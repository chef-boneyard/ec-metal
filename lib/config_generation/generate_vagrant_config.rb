require './lib/config_generation/generate_config.rb'

module EcMetal
  class GenerateVagrantConfig < GenerateConfig

    def set_provider_data()
      @config["vagrant_options"] = {
          :box => "opscode-#{ECMetal::Config.platform}",
          :disk2_size => '2',
          # TODO(jmink) There must be a better way
          :box_url => "http://opscode-vm-bento.s3.amazonaws.com/vagrant/virtualbox/opscode_#{ECMetal::Config.platform}_chef-provisionerless.box" }
    end

    def generate_standalone
      {
        :hostname => "api.opscode.piab",
        :memory => '2560',
        :cpus => '2',
        :ipaddress => "33.33.33.33",
      }
    end

    def generate_backend(n)
      {
        :hostname => "backend#{n}.opscode.piab",
        :memory => '2560',
        :cpus => '2',
        :ipaddress => "33.33.33.#{21+n}",
        :cluster_ipaddress => "33.33.34.#{5+n}"
      }
    end

    def generate_frontend(n)
      {
         :hostname => "frontend#{n}.opscode.piab",
         :memory => '1024',
         :cpus => '1',
         :ipaddress => "33.33.33.#{21 + @config[:layout][:backends].keys.size + n}",
      }
    end

    def provider_specific_config_modification()
      # Vagrant requires a virtual host mapping from names to Ips
      @config[:layout][:virtual_hosts] = {
        "private-chef.opscode.piab" => "33.33.33.23",
        "manage.opscode.piab" => "33.33.33.23",
        "api.opscode.piab" => "33.33.33.23",
        "analytics.opscode.piab" => "33.33.33.23",
        "backend.opscode.piab" => "33.33.33.21",
        @config[:layout][:backend_vip][:hostname] => @config[:layout][:backend_vip][:ipaddress]
      }
      @config[:layout][:backends].each do |k,v|
        @config[:layout][:virtual_hosts][v[:hostname]] = v[:ipaddress]
      end
      @config[:layout][:frontends].each do |k,v|
        @config[:layout][:virtual_hosts][v[:hostname]] = v[:ipaddress]
      end
    end
  end
end
