<xsl:transform version="1.0"
               xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
               xmlns:default="http://www.openarchives.org/OAI/2.0/"
               xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
               xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
               xmlns:dc="http://purl.org/dc/elements/1.1/"
               xmlns:doc="http://www.lyncode.com/xoai">
   <xsl:output method="xml" encoding="UTF-8" indent="yes"/>


<!-- This XSLT file is targeted to Libris Uppsök (http://uppsok.libris.kb.se) and
     transforms a requested OAI-PMH XML from DSpace format to a Libris compatible XML.
     It is used by the GUPEA system, when Libris makes a request like the following:
     "https://gupea.ub.gu.se/oai/request?verb=ListRecords&metadataPrefix=uppsok"
     (A resumptionToken parameter, however, needs to be added after the first request.)

     What actually happens in the transform is that the text content of any
     dc:uppsok elements in the metadata section of a record will be moved to new
     setSpec elements in the header section of the record, and no dc:uppsok elements
     will appear in the metadata section after the transform has been made
     Everything else is copied. That includes records without any metadata section.

     Note: The target XML will not look exactly like the source, but with setSpec
           lines added and dc:uppsok lines removed. In addition to layout changes
           made by the XSLT engine, some namespace info may be changed due to
           the "namespace fixup" performed by the engine. -->


   <!-- =================== -->
   <!--    Root template    -->
   <!-- =================== -->

   <!-- Wrap everything up. -->

   <xsl:template match="@*|node()">
      <xsl:copy>
         <xsl:apply-templates select="@*|node()" />
      </xsl:copy>
   </xsl:template>


   <!-- ========================== -->
   <!--    ListRecords template    -->
   <!-- ========================== -->

   <!-- For each record element in ListRecords:
           0. Copy/reproduce everything, except for dc:uppsok element(s), to the target XML.
           1. Read text in dc:uppsok element(s) in the source metadata section.
           2. Create new setSpec element(s) in the target header section and add the text to it/them.

        For resumptionToken element ending ListRecords, just copy it. -->

   <xsl:template match="/default:OAI-PMH/default:ListRecords">
      <xsl:element name='ListRecords' namespace="http://www.openarchives.org/OAI/2.0/">
         <xsl:copy-of select="./@*"/>

         <!-- [A] Transform records -->
         <xsl:for-each select="./default:record">

            <!-- Transform record -->
            <xsl:element name='record' namespace="http://www.openarchives.org/OAI/2.0/">
               <xsl:copy-of select="./@*"/>

               <!-- (a) Header section -->
               <xsl:element name='header' namespace="http://www.openarchives.org/OAI/2.0/">
                  <xsl:copy-of select="default:header/@*"/>
                  <xsl:for-each select="./default:header/*">
                     <xsl:copy-of select="."/>
                  </xsl:for-each>

                  <!-- 1 & 2: Read dc:uppsok text in source metadata section &
                              create new setSpec element(s) in target header section -->
                  <xsl:for-each select="./default:metadata/oai_dc:dc/dc:uppsok">
                     <xsl:element name='setSpec' namespace="http://www.openarchives.org/OAI/2.0/">
                        <xsl:value-of select="."/>
                     </xsl:element>
                  </xsl:for-each>

               </xsl:element>

               <!-- (b) Metadata section -->
               <!-- Copy source metadata (except for dc:uppsok elements) to target metadata,
                                                                 if metadata section exists -->
               <xsl:for-each select="./default:metadata"> <!-- 0 or 1 metadata sections -->
                  <xsl:element name='metadata' namespace="http://www.openarchives.org/OAI/2.0/">
                     <xsl:copy-of select="./@*"/>
                     <xsl:for-each select="./*">
                        <xsl:apply-templates select="."/>
                     </xsl:for-each>
                  </xsl:element>
               </xsl:for-each>

            </xsl:element> <!-- record transformed -->
         </xsl:for-each> <!-- records transformed -->

         <!-- [B] Copy source resumptionToken -->
         <xsl:copy-of select="./default:resumptionToken"/>

      </xsl:element>
   </xsl:template>

   <!-- ======================== -->
   <!--    dc:uppsok template    -->
   <!-- ======================== -->

   <!-- Omit dc:uppsok metadata when copying. -->

   <xsl:template match="//dc:uppsok"/>

</xsl:transform>
