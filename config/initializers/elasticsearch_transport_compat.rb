# Compatibility shim for elasticsearch-rails expecting nested transport access.
# Some client/transport combinations return the HTTP adapter directly.
if defined?(Elasticsearch::Transport::Transport::HTTP::Faraday)
  faraday_transport = Elasticsearch::Transport::Transport::HTTP::Faraday
  unless faraday_transport.method_defined?(:transport)
    faraday_transport.class_eval do
      def transport
        self
      end
    end
  end
end
