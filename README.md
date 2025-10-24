# Gupea-xslt-uppsok

Gupea-ext-xslt-uppsok extends DSpace by acting as an external http-based transformation layer, i.e. without changing the DSpace source code. The extension is accessed on the same host as DSpace: `https://gupea.ub.gu.se/oai-uppsok/request?verb=ListRecords&metadataPrefix=uppsok&set=com_2077_785`. In contrast to DSpace, it is based on Ruby technology. Puma is used as app server, and the Sinatra framework takes care of the routing.
