class Group < ActiveXML::Node

  default_find_parameter :title
  handles_xml_element :group

  def self.list(prefix = nil, opts = {})
    opts[:login] ||= ''
    prefix ||= ''
    prefix = URI.encode(prefix)
    group_list = Rails.cache.fetch("group_list_#{ opts[:login] }_#{prefix.to_s}", :expires_in => 10.minutes) do
      transport ||= ActiveXML::transport
      path = "/group?prefix=#{prefix}&login=#{ opts[:login] }"
      begin
        logger.debug "Fetching group list from API"
        response = transport.direct_http URI("#{path}"), :method => "GET"
        names = []
        Collection.new(response).each {|group| names << group.name}
        names
      rescue ActiveXML::Transport::Error => e
        raise ListError, e.summary
      end
    end
    return group_list
  end
end





