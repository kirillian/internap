require 'soap/wsdlDriver'
require 'digest'

################################################################################
#
# Ruby Adaptor for making soap calls to the Internap Web Service
# For creating and updating streams. Uses the standard soap library
# provided by Ruby to communicate and the digest library to create
# the necessary hash.
#
# Created June 7, 2010 12:33PM CST
# John Epperson
#
################################################################################

class InternapAdaptor
	attr_accessor :wsdl_url, :username, :password, :wsdl

	def initialize(wsdl_url, username = nil, password = nil)
		connect(wsdl_url, username, password)
	end

	def connect(wsdl_url, username = nil, password = nil)
		@wsdl_url = wsdl_url
		@username = username
		@password = password
		@wsdl = wsdl.create_rpc_driver
	end

	def disconnect
		@wsdl = nil
	end

	def connected?
		!@wsdl.nil?
	end

	def create_pub_point(name, source, publishing_point_type, location, secure)
		response = @wsdl.CreatePubPoint(:strHash => hash, :strUserName => @username, :strPubPointName => name, :strSource => source, :enumPubPointType => publishing_point_type, :enumLocation => location, :blnSecure => secure)
		@wsdl.reset_stream
		response.createPubPointResult

	rescue SOAP::FaultError => exception
		return nil_pub_point
	end
	
	def create_or_overwrite_pub_point(name, source, publishing_point_type, location, secure)
		response = @wsdl.CreateOrOverWritePubPoint(:strHash => hash, :strUserName => @username, :strPubPointName => name, :strSource => source, :enumPubPointType => publishing_point_type, :enumLocation => location, :blnSecure => secure)
		@wsdl.reset_stream
		response.createOrOverWritePubPointResult

	rescue SOAP::FaultError => exception
		return nil_pub_point
	end

	def create_or_overwrite_pub_point_with_instance(name, source, publishing_point_type, location, secure, instance)
		response = @wsdl.CreateOrOverWritePubPointWithInstance(:strHash => hash, :strUserName => @username, :strPubPointName => name, :strSource => source, :enumPubPointType => publishing_point_type, :enumLocation => location, :blnSecure => secure, :instance => instance)
		@wsdl.reset_stream
		response.createOrOverWritePubPointWithInstance

	rescue SOAP::FaultError => exception
		return nil_pub_point
	end

	def get_account_locations
		response = @wsdl.GetAccountLocations(:strHash => hash, :strUserName => @username)
		@wsdl.reset_stream
		response.getAccountLocationsResult.vS_LocationRef

	rescue SOAP::FaultError => exception
		return nil_pub_point
	end

	def get_FVSS_pub_point(name)
		response = @wsdl.GetFVSSPubPoint(:strHash => hash, :strUserName => @username, :strPubPointName => name)
		@wsdl.reset_stream
		response.getFVSSPubPointResult
	rescue SOAP::FaultError => exception
		return nil_pub_point
	end

	def get_FVSS_pub_points
		response = @wsdl.GetFVSSPubPoints(:strHash => hash, :strUserName => @username)
		@wsdl.reset_stream
		list = response.getFVSSPubPointsResult.vS_FVSSPubPoint rescue []
		if !list.respond_to?("each")
			list = Array.new().push(list)
		end

		list

	rescue SOAP::FaultError => exception
		return nil_pub_point
	end

	def remove_pub_point(name, secure)
		response = @wsdl.RemovePubPoint(:strHash => hash, :strUserName => @username, :strPubPointName => name, :blnSecure => secure)
		@wsdl.reset_stream
		response.removePubPointResult

	rescue SOAP::FaultError => exception
		return nil_pub_point
	end

	def update_pub_point(name, source, publishing_point_type, location, compartment_id, status, cluster_id, secure)
		response = @wsdl.UpdatePubPoint(:strHash => hash, :strUserName => @username, :strPubPointName => name, :strSource => source, :enumType => publishing_point_type, :enumLocation => location, :intCompartmentID => compartment_id, :intStatus => status, :intClusterID => cluster_id, :blnSecure => secure)
		@wsdl.reset_stream
		response.updatePubPointResult
		
	rescue SOAP::FaultError => exception
    	return nil_pub_point
	end

	protected

	def wsdl
		SOAP::WSDLDriverFactory.new("#{@wsdl_url}?WSDL")
	end

	def hash
		Digest::MD5.hexdigest(@username + @password)
	end

	def nil_pub_point
		nil
	end
end