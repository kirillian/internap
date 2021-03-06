require 'internap/internap_adaptor.rb'
require 'internap/internap_publishing_points.rb'
require 'yaml'

################################################################################
#
# Ruby API to provide DRY implementation of the Internap Adaptor while still
# providing the same flexibility.
#
# Created June 28, 2010 3:06PM CST
# John Epperson
#
################################################################################

class Internap
	include Singleton
	
	def initialize
		if File.exists?(File.join(File.expand_path(RAILS_ROOT), "config","internap.yml"))
			config = YAML.load_file(File.join(File.expand_path(RAILS_ROOT), "config","internap.yml"))
			@@internap_connection_url = config["internap"]["connection_url"]
			@@username = config["internap"]["username"]
			@@password = config["internap"]["password"]
			@@default_stream_location = config["stream"]["location"]
			@@default_publishing_point_type = config["stream"]["publishing_point_type"]
			@@default_secure_setting = (config["stream"]["secure"] == 'true')
		end
		
		@@internap_adaptor = InternapAdaptor.new(@@internap_connection_url, @@username, @@password)

		if !@@internap_adaptor.connected?
			raise InternapSoapConnectionError, "Internap adaptor could not properly connect to the internap web service. Verify that the authentication credentials provided in config/internap.yml are valid"
		end
	end

	def self.create_broadcast_publishing_point(stream_name, location = @@default_stream_location, publishing_point_type = @@default_publishing_point_type, secure_setting = @@default_secure_setting)
		@@internap_adaptor.create_or_overwrite_pub_point(stream_name, LOCATIONS[location.to_sym][:url], publishing_point_type, LOCATIONS[location.to_sym][:name], secure_setting)
	end

	def self.remove_publishing_point(stream_name, secure_setting = @@default_secure_setting)
		@@internap_adaptor.remove_pub_point(stream_name, secure_setting)
	end

	def self.modify_publishing_point(stream_name, location = @@default_stream_location, publishing_point_type = @@default_publishing_point_type, secure_setting = @@default_secure_setting)
		stream = self.map_internap_publishing_point_info(self.get_publishing_point(stream_name))
		@@internap_adaptor.update_pub_point(stream_name, LOCATIONS[location.to_sym][:url], publishing_point_type, LOCATIONS[location.to_sym][:name], stream[:compartment_ref_id], stream[:status], stream[:fvss_gateway_cluster_id], secure_setting)
	end

	def self.current_publishing_points()
		@@internap_adaptor.get_FVSS_pub_points()
	end

	def self.get_publishing_point(stream_name)
		@@internap_adaptor.get_FVSS_pub_point(stream_name)
	end
	
	class InternapError < StandardError; end

	protected

	def self.map_internap_publishing_point_info(publishing_point_info)
		{:fvss_pub_points_id => publishing_point_info.vS_FVSSPubPointsID,
		  :fvss_gateway_cluster_id => publishing_point_info.vS_FVSSGatewayClusterID,
		  :compartment_ref_id => publishing_point_info.vS_CompartmentRefID,
		  :domain_id => publishing_point_info.domainID,
		  :name => publishing_point_info.name,
		  :local_application_name => publishing_point_info.localApplicationName,
		  :status => publishing_point_info.status,
		  :single_pull_location => publishing_point_info.singlePullLocation,
		  :source => publishing_point_info.source,
		  :type => publishing_point_info.type,
		  :server_side_buffer => publishing_point_info.serverSideBuffer,
		  :delete_pending? => publishing_point_info.isDeletePending,
		  :created => publishing_point_info.created,
		  :deleted => publishing_point_info.deleted
		}
	end
end

Internap.instance