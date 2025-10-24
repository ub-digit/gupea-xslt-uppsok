require_relative 'log.rb'

module Error

   # This module is responsible for producing error XML. It also takes care of forwarding
   # non 200 responses from DSpace, and detecting error messages in 200 responses from DSpace.

   def self.extract_possible_error_from_dspace_200_response(response)
      match = /error code="(.+)"\>(.*)<\/error>/.match(response)
      if match
         code = match[1]
         text = match[2]
      else
         match = /error code="(.+)"\/\>/.match(response)
         code = match[1] if match
      end
      "#{code} (#{text ? text : '-'})" if match
   end

   def self.forward_non_200_dspace_response(response, app)
      Log.forwarded_non_200_response_from_dspace(response)
      app.halt(response.code, response.body)
   end

   def self.handle_errors(type, errors, base_url_from_libris, app)
      timestamp   = Time.now.utc.iso8601    # OAI-PMH compatible timestamp
      error_lines = errors.map { |e| "  <error code=\"#{e[:code]}\">#{e[:text]}</error>" }.join("\n")
      error_xml   = ['<?xml version="1.0" encoding="UTF-8"?>',
                     '<OAI-PMH xmlns="http://www.openarchives.org/OAI/2.0/',
                     '         xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance',
                     '         xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/',
                     '         http://www.openarchives.org/OAI/2.0/OAI-PMH.xsd">',
                     "  <responseDate>#{timestamp}</responseDate>",
                     "  <request>#{base_url_from_libris}</request>",
                     error_lines,
                     '</OAI-PMH>'].join("\n")
      send_error_xml_to_libris(type, error_xml, app)
   end

   ###################
   # Private method

   class << self

      private def send_error_xml_to_libris(type, error_xml, app)
         case type
         when :xslFileValidationError
            Log.error(200, "xslFile parameter not valid" , error_xml)
            app.halt(200, error_xml)
         when :dSpaceUnreachable
            Log.error(500, "DSpace unreachable error"    , error_xml)
            app.halt(500, error_xml)
         when :dSpaceXmlGenerationError
            Log.error(500, "XML from DSpace not valid"   , error_xml)
            app.halt(500, error_xml)
         else # Only an error in the ext-xslt-uppsok code would result in this default
            Log.error(500, "Invalid error type used"     , error_xml)
            app.halt(500, error_xml)
         end
      end
   end
end

