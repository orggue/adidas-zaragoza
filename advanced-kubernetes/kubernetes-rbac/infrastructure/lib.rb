###############
## CONFIGURATION


EXTRA_USERS = ["alice","bobby","monkey"]

class Configuration
  attr_reader :project
  attr_reader :nr_clusters
  attr_reader :extra_users
  attr_reader :zone

  class User
    attr_reader :full_name, :is_admin, :cluster

    def initialize(full_name, is_admin, cluster)
      @full_name = full_name
      @is_admin = is_admin
      @cluster = cluster
    end

    def short_name
      @full_name.split("@").first
    end
  end

  def self.from_file(config_file)
    Configuration.new(YAML.load(File.read(config_file)))
  end

  def initialize(config)
    @project = config["project"]
    @nr_clusters = config["nr_clusters"]
    @zone = config["zone"]
    @extra_users = config["extra_users"]
  end
  
  def all_users
    result = []
    self.nr_clusters.times.each do |i|
      result.push User.new("admin-#{i}@#{self.project}.iam.gserviceaccount.com", true, "k#{i}")
      EXTRA_USERS.each do |usr|
        result.push User.new("#{usr}-#{i}@#{self.project}.iam.gserviceaccount.com", false, "k#{i}")
      end
    end
    result
  end
end

###############
#### IO HELPERS

def capture_or_die(cmd)
  stdout, stderr, status = Open3.capture3(cmd)

  if status.success?
    stdout
  else
    raise "Failed during execution of #{cmd}.\nSTDOUT:\n#{stdout}\nSTDERR:\n#{stderr}"
  end
end

def capture_json_or_die(cmd)
  JSON.load capture_or_die(cmd)
end


#####################
### Low level helpers

def project_exists?(id)
  capture_json_or_die("gcloud projects list --format json").select { |project| project["projectId"] == id }.any?
end

def get_clusters(config)
  capture_json_or_die("gcloud container clusters list --project=#{config.project} --format json")
end

def get_project_policy(config)
  capture_json_or_die("gcloud projects get-iam-policy #{config.project} --format json")
end


def get_k8s_credenials(config)
  puts "Fetching k8s credentials"
  credentials = {}
  config.nr_clusters.times do |nr|
    name = "k#{nr}"
    path = "cache/k8s-creds/#{config.project}/#{name}"
    FileUtils.mkdir_p(File.dirname(path))
    if File.exists?(path)
    else
      puts "- Fetching with gcloud"
      capture_or_die("KUBECONFIG=#{path} gcloud container clusters get-credentials #{name}")
    end
    credentials[name]=path
  end

  credentials
end

def get_service_accounts(config)
  capture_json_or_die("gcloud iam service-accounts list --project #{config.project} --format json") 
end



##########################
##### Higher level helpers

def ensure_gcloud_settings!(config)
  puts "#### CHECKING GCLOUD SETTINGS"
  if `gcloud config get-value project 2>/dev/null`.chomp != config.project
    puts "Setting project"
    capture_or_die("gcloud config set project #{config.project}")
  end

  if `gcloud config get-value zone 2>/dev/null`.chomp != config.zone
    puts "Setting compute/zone"
    capture_or_die("gcloud config set compute/zone #{config.zone}")
  end
end

def ensure_project_exists!(config)
  if project_exists?(config.project)
    puts "Project #{config.project} exists"
  else
    puts "Project #{config.project} does not exists, create it with gcloud or the UI."
    exit 1
  end
end

def ensure_nr_clusters!(config)
  puts "Ensuring that there will be #{config.nr_clusters} clusters"
  clusters = get_clusters(config)
  cluster_names = clusters.map { |c| c["name"] }

  config.nr_clusters.times do |x|
    name = "k#{x}"
    print "Checking #{name} "
    if cluster_names.include?(name)
      puts "exists!"
    else
      puts "does not exist; triggering creation"
      capture_or_die("gcloud beta container clusters create #{name} --num-nodes=1 --async --project=#{config.project}")
    end
  end
end

def ensure_global_policies!(config)
  puts "#### ENSURING CONTAINER ADMIN POLICIES"

  # Compute what the new members should be
  admins = config.all_users.select { |user| user.is_admin }
  new_members = admins.map { |user| "serviceAccount:" + user.full_name }

  # Get existing view policy members
  policy = get_project_policy(config)
  existing_viewers = policy["bindings"].find { |binding| binding["role"] == "roles/container.admin" }
  if existing_viewers != nil
    viewers = existing_viewers
  else
    viewers = { "members" => [], "role" => "roles/container.admin" }
    policy["bindings"].push viewers
  end

  # Check if current state is what we desire.
  if new_members.sort == viewers["members"].sort
    puts "Already up2date"
  else
    puts "Updating policy"
    viewers["members"] = new_members

    Tempfile.open("policyfile.json") do |tf|
      tf.write(JSON.dump(policy))
      tf.sync
      tf.close
      capture_json_or_die("gcloud projects set-iam-policy #{config.project} #{tf.path} --format json")
    end
  end
end

def ensure_k8s_admins!(config)
  puts "#### SET K8S ADMIN ACCOUNTS"

  # Gather k8s credentials
  # Then apply admin permissions to the first len(admin) clusters
  creds = get_k8s_credenials(config)

  admins = config.all_users.select { |u| u.is_admin }

  admins.each do |admin|
    kubehome = creds[admin.cluster]

    configuration = {
        "apiVersion": "rbac.authorization.k8s.io/v1beta1",
        "kind": "ClusterRoleBinding",
        "metadata": {
            "name": "workshop-admin",
        },
        "roleRef": {
            "apiGroup": "rbac.authorization.k8s.io",
            "kind": "ClusterRole",
            "name": "cluster-admin"
        },
        "subjects": [{ 
          "kind": "User",
          "name": admin.full_name
        }]
    }

    puts "Making '#{admin.short_name}' admin of cluster #{admin.cluster}"

    # Run kubectl to apply the admin role.
     Open3.popen3("KUBECONFIG=#{kubehome} kubectl apply -f -") do |stdin, _stdout, stderr, process|
       stdin.puts(JSON.dump(configuration))
       stdin.close
       exit_status = process.value
       if !exit_status.success?
         puts "kubectl apply adminrole failed"
         puts stderr.read
         puts stdout.read
       end
     end
  end
end

def wait_until_all_clusters_ready!(config)
  puts "#### CHECKING IF ALL CLUSTERS ARE READY"
  loop do

    # Getting all clusters, convert into hashmap from array.
    clusters = {}

    get_clusters(config).each do |c|
      clusters[c["name"]] = c
    end

    # Now filter all workshop clusters
    workshop_clusters = []
    config.nr_clusters.times do |x|
      name = "k#{x}"
      cluster = clusters[name]
      raise "hmz, should be checked in 'ensure_nr_clusters!' #{name}" if cluster.nil?
      workshop_clusters.push cluster
    end

    # Pick all workshops that are not RUNNING.
    not_running = workshop_clusters.select { |c| c["status"] != "RUNNING" }

    if not_running.empty?
      puts "All clusters are ready!"
      break
    else
      puts "There are #{not_running.length} workshop clusters are not in state 'RUNNING', waiting until they become 'RUNNING': " + not_running.map { |c| "#{c["name"]}=#{c["status"]}"}.join(" ")
      puts "Retrying in 2 seconds"
      sleep 2
    end
  end
end

def ensure_service_accounts!(config)
  puts "#### ENSURING SERVICE ACCOUNTS EXIST"

  service_accounts = get_service_accounts(config)
  service_account_full_names  = service_accounts.map { |sa| sa["name"].split("/").last }
  service_account_short_names = service_account_full_names.map { |n| n.split("@").first }

  config.all_users.each do |user|
    if service_account_short_names.include?(user.short_name)
      puts "#{user.short_name} exists"
    else
      puts "creating  #{user.short_name}"
      capture_or_die("gcloud iam service-accounts create #{user.short_name} --project #{config.project}")
    end
  end
end

def ensure_service_account_keys!(config)
  puts "#### SERVICE ACCOUNT KEYS"
  config.all_users.each do |user|
    key_file = "participant-instructions/#{config.project}/#{user.cluster}/keys/#{user.short_name}"
    dir = File.dirname(key_file)
    FileUtils.mkdir_p(dir)
    if !File.exists?(key_file)
      puts "creating key for #{user.short_name}"
      capture_or_die("gcloud iam service-accounts keys create #{key_file} --iam-account #{user.full_name}")
    end
  end
end

def gen_instructions!(config)
  puts "#### GENERATING INSTRUCTIONS"

  config.all_users.each do |user|
    dir = "participant-instructions/#{config.project}/#{user.cluster}/"

    # start_container.sh
    FileUtils.cp("template/start_container.sh", dir)
    FileUtils.cp_r("template/bin", dir)
  end

  # Hack
  config.nr_clusters.times.each do |i|
    dir = "participant-instructions/#{config.project}/k#{i}/"
    capture_or_die("find #{dir} -type f | xargs sed -i 's/PROJECT_ID/#{config.project}/'")
    capture_or_die("find #{dir} -type f | xargs sed -i 's/COMPUTE_ZONE/#{config.zone}/'")
    capture_or_die("find #{dir} -type f | xargs sed -i 's/CLUSTER_NAME/k#{i}/'")

    capture_or_die("find #{dir} -type f | xargs sed -i 's/ADMIN_SHORT/#{"admin-#{i}"}/'")
    capture_or_die("find #{dir} -type f | xargs sed -i 's/ALICE_SHORT/#{"alice-#{i}"}/'")
    capture_or_die("find #{dir} -type f | xargs sed -i 's/BOBBY_SHORT/#{"bobby-#{i}"}/'")
    capture_or_die("find #{dir} -type f | xargs sed -i 's/MONKEY_SHORT/#{"monkey-#{i}"}/'")

    capture_or_die("find #{dir} -type f | xargs sed -i 's/ADMIN_ACCOUNT/#{"admin-#{i}@#{config.project}.iam.gserviceaccount.com"}/'")
    capture_or_die("find #{dir} -type f | xargs sed -i 's/ALICE_ACCOUNT/#{"alice-#{i}@#{config.project}.iam.gserviceaccount.com"}/'")
    capture_or_die("find #{dir} -type f | xargs sed -i 's/BOBBY_ACCOUNT/#{"bobby-#{i}@#{config.project}.iam.gserviceaccount.com"}/'")
    capture_or_die("find #{dir} -type f | xargs sed -i 's/MONKEY_ACCOUNT/#{"monkey-#{i}@#{config.project}.iam.gserviceaccount.com"}/'")
  end
end
