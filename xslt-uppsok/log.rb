module Log

   # This module is responsible for providing log messages to STDOUT.

   INTRO = "[ext-xslt-uppsok]"

   def self.running_xslt_uppsok(request_url_from_libris)
      puts ["#{INTRO} ------- Running XsltUppsok (#{timestamp}) -------",
            "#{INTRO} Request URL (XsltUppsok): #{request_url_from_libris}",
            ""].join("\n")
   end

   def self.sending_request_to_dspace(url_dspace)
      puts ["#{INTRO} Request URL (DSpace):     #{url_dspace}",
            "#{INTRO} Sending request to DSpace (#{timestamp})",
            ""].join("\n")
   end

   def self.received_valid_200_response_from_dspace(error_text)
      error_part = error_text ? "Error: #{error_text}" : "No errors received from DSpace"
      puts ["#{INTRO} [200] Status 200 response with valid XML received from DSpace (#{timestamp})",
            "#{INTRO}   #{error_part}",
            ""].join("\n")
   end

   def self.forwarded_non_200_response_from_dspace(response)
      puts ["#{INTRO} [#{response.code}] Non 200 response received from DSpace (#{timestamp}):",
            "#{INTRO}   response code: #{response.code}",
            "#{INTRO}   response body:",
            "#{INTRO}     #{response.body}",
            ""].join("\n")
   end

   def self.error(status_code, log_item_intro, error_xml)
      puts ["#{INTRO} [#{status_code}] #{log_item_intro} (#{timestamp}):",
            "#{INTRO}   #{error_xml}",
            ""].join("\n")
   end

   class << self

      private def timestamp()
         Time.now.iso8601(3)
      end
   end
end

