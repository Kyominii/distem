require 'wrekavoc'
require 'rest_client'
require 'json'
require 'cgi'
require 'pp'

module Wrekavoc
  module NetAPI

    class Client
      HTTP_STATUS_OK = 200

      def initialize(serveraddr,port=4567)
        raise unless port.is_a?(Numeric)
        @serveraddr = serveraddr
        @serverurl = 'http://' + @serveraddr + ':' + port.to_s
        @resource = RestClient::Resource.new(@serverurl)
      end

      # Initialize a physical node (create cgroups structure, set up the network interfaces, ...)
      # This step is required to be able to set up some virtual node on a physical one
      # ==== Attributes
      # * +target+ The hostname/address of the physical node
      # ==== Returns
      # The physical node which have been initialized (Hash)
      def pnode_init(target = NetAPI::TARGET_SELF)
        begin
          ret = {}
          req = "/pnodes"
          @resource[req].post(
            {:target => target}
          ) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      def pnode_info(pnodename)
        begin
          ret = {}
          req = "/pnodes/#{pnodename}"
          @resource[req].get { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      def pnodes_info()
        begin
          ret = {}
          req = "/pnodes"
          @resource[req].get { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      # Create a virtual node using a specific filesystem compressed image (if no physical node is specified, a random one is selected)
      # ==== Attributes
      # * +name+ The name of the virtual node which should be unique
      # * +properties+ A Hash (or a JSON string) with the parameters used to set up the virtual node
      # * * +image+ The URI to the (compressed) image file used to set up the file system
      # * * +target+ (optional) The hostname/address of the physical node to set up the virtual one on
      # ==== Returns
      # The virtual node which have been created (Hash)
      def vnode_create(name, properties)
        begin
          properties = properties.to_json if properties.is_a?(Hash)

          ret = {}
          req = '/vnodes'
          @resource[req].post(
            { :name => name , :properties => properties }
          ) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      def vnode_info(vnodename)
        begin
          ret = {}
          req = "/vnodes/#{vnodename}"
          @resource[req].get { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      # Start a virtual node 
      # ==== Attributes
      # * +vnodename+ The name of the virtual node
      # ==== Returns
      # The virtual node (Hash)
      def vnode_start(vnode)
        begin
          ret = {}
          req = "/vnodes/#{vnode}"
          @resource[req].put(
            { :status => Resource::VNode::Status::RUNNING }
          ) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      # Stop a virtual node 
      # ==== Attributes
      # * +vnodename+ The name of the virtual node
      # ==== Returns
      # The virtual node (Hash)
      def vnode_stop(vnode)
        begin
          ret = {}
          req = "/vnodes/#{vnode}"
          @resource[req].put(
            { :status => Resource::VNode::Status::STOPPED }
          ) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      # Create a virtual interface on the virtual node
      # ==== Attributes
      # * +vnodename+ The name of the virtual node
      # * +vifacename+ The name of the virtual interface to be created (have to be unique on that virtual node)
      # ==== Returns
      # The virtual interface which have been created (Hash)
      def viface_create(vnode, name)
        begin
          ret = {}
          req = "/vnodes/#{vnode}/vifaces"
          @resource[req].post(
            { :name => name }
          ) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      def viface_info(vnodename, vifacename)
        begin
          ret = {}
          req = "/vnodes/#{vnodename}/vifaces/#{vifacename}"
          @resource[req].get(
          ) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      # Set a virtual node in gateway mode (add the ability to forward traffic)
      # ==== Attributes
      # * +vnodename+ The name of the virtual node
      # ==== Returns
      # The virtual node (Hash)
      def vnode_gateway(vnode)
        begin
          ret = {}
          req = "/vnodes/#{vnode}/mode"
          @resource[req].put(
            { :mode => Resource::VNode::MODE_GATEWAY }
          ) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      def vnode_info_rootfs(vnode)
        @resource['/vnodes/infos/rootfs'].post :vnode => vnode
      end

      def vnodes_info()
        begin
          ret = {}
          req = "/vnodes"
          @resource[req].get({}) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      # Create a new vitual network
      # ==== Attributes
      # * +name+ The name of the virtual network (unique)
      # * +address+ The address (CIDR format: 10.0.8.0/24) the virtual network will work with 
      # ==== Returns
      # The virtual network which have been created (Hash)
      def vnetwork_create(name, address)
        begin
          ret = {}
          req = "/vnetworks"
          @resource[req].post(
            { :name => name, :address => address }
          ) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      def vnetwork_info(vnetworkname)
        begin
          ret = {}
          req = "/vnetworks/#{vnetworkname}"
          @resource[req].get { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      def vnetworks_info()
        begin
          ret = {}
          req = "/vnetworks"
          @resource[req].get { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      # Connect a virtual interface on a network with (optionally) some limitations
      # ==== Attributes
      # * +vnode+ The name of the virtual node
      # * +viface+ The name of the virtual interface
      # * +properties+ An Hash (or a JSON string) containing the parameters to set up the connection
      # * * +vnetwork+ The name of the virtual network to connect the interface on
      # * * +address+ The address of the virtual interface
      # One of this two parameters have to be set (if it's vnetwork, the address is automatically set)
      # * * +limitations+ ...
      # ==== Returns
      # The virtual interface (Hash)
      def viface_attach(vnode, viface, properties)
        begin
          properties = properties.to_json if properties.is_a?(Hash)
          ret = {}
          req = "/vnodes/#{vnode}/vifaces/#{viface}"
          @resource[req].put(
            { :properties => properties }
          ) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      # Create a new virtual route between two virtual networks ("NetDestination is accessible from NetSource using NodeGateway")
      # ==== Attributes
      # * +srcnet+ The name of the source virtual network
      # * +destnet+ The name of the destination virtual network
      # * +gateway+ The name of the virtual node to use as gateway (this node have to be connected on both of the previously mentioned networks), the node is automatically set in gateway mode
      # ==== Returns
      # The virtual route which have been created (Hash)

      def vroute_create(srcnet,destnet,gateway,vnode="")
        begin
          ret = {}
          req = "/vnetworks/#{srcnet}/vroutes"
          @resource[req].post(
            { :destnetwork => destnet,
              :gatewaynode => gateway, :vnode => vnode }
          ) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      # Create all possible virtual routes between all the virtual networks, automagically choosing the virtual nodes to use as gateway
      # ==== Returns
      # All the virtual routes which have been created (Array of Hashes)

      def vroute_complete()
        begin
          ret = {}
          req = "/vnetworks/vroutes/complete"
          @resource[req].post({}) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      # Execute the specified command on the virtual node
      # ==== Attributes
      # * +vnode+ The name of the virtual node
      # * +command+ The command to be executed
      # ==== Returns
      # A Hash with the command which have been performed and the resold of it

      def vnode_execute(vnode, command)
        begin
          ret = {}
          req = "/vnodes/#{vnode}/commands"
          @resource[req].post(
            { :command => command }
          ) { |response, request, result|
            ret = JSON.parse(check_error(result,response))
          }
          return ret
        rescue RestClient::RequestFailed
          raise Lib::InvalidParameterError, "#{@serverurl}#{req}"
        rescue RestClient::Exception, Errno::ECONNREFUSED, Timeout::Error, \
          RestClient::RequestTimeout, Errno::ECONNRESET, SocketError
          raise Lib::UnavailableResourceError, @serverurl
        end
      end

      protected

      def check_error(result,response)
        case result.code.to_i
          when HTTP_STATUS_OK
          else
            begin
              body = JSON.parse(response)
            rescue JSON::ParserError
              body = response
            end

            raise Lib::ClientError.new(
              result.code.to_i,
              response.headers[:x_application_error_code],
              body
            )
        end
        return response
      end
    end

  end
end
