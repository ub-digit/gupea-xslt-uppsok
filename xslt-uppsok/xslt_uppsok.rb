require_relative 'error.rb'
require_relative 'log.rb'

require 'nokogiri'
require 'httparty'
require 'uri'

module XsltUppsok

  # This module is responsible for transforming the result of an oai request
  # to Gupea made by Libris Uppsök (http://uppsok.libris.kb.se/sru/uppsok),
  # since the format delivered from DSpace needs a slight change to be fully
  # understandable by Libris.
  #
  # For the transformation, the modules uses XSLT and thus needs an xsl file.
  # The name of the default xsl file should be provided as an environment
  # variable. There is, however, also an option to supply the name of an
  # overriding xsl file as a parameter to the web service. All the parameters
  # are provided as input to the run method.

  DEFAULT_DSCAPE2LIBRIS_XSL_FILE = 'uppsok-dspace2libris.xsl'
  DSPACE_HOST = ENV['DSPACE_HOST']
  DSPACE_PORT = ENV['DSPACE_PORT']

  def self.run(params, request_url_from_libris, app)
    Log.running_xslt_uppsok(request_url_from_libris)
    base_url_from_libris = remove_query_from_request_url_from_libris(request_url_from_libris) # used for error XML
    query_to_send_to_dspace = create_dspace_query(request_url_from_libris)
    dspace_xml_string = request_dspace_xml_string(
      query_to_send_to_dspace,
      base_url_from_libris,
      app
    )
    transform_dspace_xml_string_to_libris_xml_string(
      dspace_xml_string,
      params,
      base_url_from_libris,
      app
    )
  end

  ########################
  # Private methods

  class << self

    private def remove_query_from_request_url_from_libris(request_url_from_libris)
      request_url_from_libris.sub(/\?.*$/ , "")
    end


    private def create_dspace_query(request_url_from_libris)
      # Extract the query part of the request URL and then remove the xslFile parameter, if any.
      query_from_libris_match = /\?(.+)$/.match(request_url_from_libris)
      query_to_dspace =
        query_from_libris_match[1] \
        # other parameters and xsl file parameter in position other than the last one
        .sub( /xslFile=[^&]+&/, "") \
        # other parameters and xsl file parameter in last position
        .sub(/&xslFile=[^&]+$/, "") \
        # xsl file as only parameter
        .sub( /xslFile=[^&]+$/, "") if query_from_libris_match
    end

    private def request_dspace_xml_string(query_to_send_to_dspace, base_url_from_libris, app)
      # [1] Build URL for the request to send to DSpace
      url_dspace = URI::HTTP.build(
        host:  DSPACE_HOST,
        port:  DSPACE_PORT,
        path:  '/server/oai/request',
        query: query_to_send_to_dspace
      ).to_s

      # [2] Communicate with DSpace
      Log.sending_request_to_dspace(url_dspace)
      dspace_response = HTTParty.get(url_dspace)

      # [3] Handle response from DSpace

      # (a) DSpace response: none
      #     Action:          Send 500 error xml
      if (!dspace_response)
        Error.handle_errors(
          :dSpaceUnreachable,
          [{
            code: :dSpaceUnreachable,
            text: "Couldn't reach DSpace"
          }],
          base_url_from_libris,
          app
        )

      # (b) DSpace response: different from 200
      #     Action:          Forward the result without XLST transformation
      elsif (dspace_response.code != 200)
        Error.forward_non_200_dspace_response(dspace_response, app)
        # (c) DSpace response: 200
        #     Action:          if the xml from DSpace is not valid xml, send 500 xml,
        #                      otherwise let it pass for XSLT transformation
      else
        dspace_response_body = dspace_response.body
        if (!is_valid_xml?(dspace_response_body))
          Error.handle_errors(
            :dSpaceXmlGenerationError,
            [{
              code: :dSpaceXmlGenerationError,
              text: "Server generated non-valid XML"
            }],
            base_url_from_libris,
            app
          )
        else
          Log.received_valid_200_response_from_dspace(
            Error.extract_possible_error_from_dspace_200_response(dspace_response_body)
          )
          dspace_response_body
        end
      end
    end

    private def is_valid_xml?(maybe_xml)
      Nokogiri::XML(maybe_xml).errors.empty?
    end


    private def transform_dspace_xml_string_to_libris_xml_string(dspace_xml_string,params,base_url_from_libris, app)
      dspace_xml_object = Nokogiri::XML(dspace_xml_string)
      libris_xml_object = load_xslt(params, base_url_from_libris, app) \
        .transform(dspace_xml_object)
      libris_xml_string = libris_xml_object.to_xml()
    end

    private def load_xslt(params, base_url_from_libris, app)
      filename = params[:xslFile] || DEFAULT_DSCAPE2LIBRIS_XSL_FILE
      xsl_path_and_filename = File.join(__dir__, '..', 'xsl', filename)
      if (!File.file?(xsl_path_and_filename))
        Error.handle_errors(
          :xslFileValidationError,
          [{
            code: :badArgument,
            text: "XSLT file #{filename} not found"
          }],
          base_url_from_libris,
          app
        )
      end
      Nokogiri::XSLT(File.open(xsl_path_and_filename, "rb"))
    end
  end
end
