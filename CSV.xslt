<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
  xmlns:fn="http://www.w3.org/2005/xpath-functions" 
  xmlns:csv="http://ns.expertml.com/csv/" 
  xmlns:xs="http://www.w3.org/2001/XMLSchema" 
  xmlns:xcsv="http://www.seanbdurkin.id.au/xslt/xcsv.xsd"
  xmlns:map="http://www.w3.org/2005/xpath-functions/map"
  version="3.0"
  exclude-result-prefixes="xsl xs fn csv map">
	
	<xsl:param name="csv:default-options" as="map(xs:string, item()*)" select="map{
				'useHeader'	:	true(),
				'sep'	:	',',
				'rootElement'	:	'csv',
				'rowElement' : 'row',
				'cellElement' : 'cell',
				'quote'	: '&quot;'
		}"/>
	
	<xsl:function name="csv:csv-to-xml" as="document-node()">
		<xsl:param name="href"/>
		<xsl:param name="raw-options" as="map(xs:string, item())*"/>
		<xsl:variable name="options" select="map:merge(($raw-options, $csv:default-options))"/>
		<xsl:variable name="header" as="xs:string*">
			<xsl:apply-templates mode="csv:cellValues" select="tokenize(unparsed-text-lines($href)[1], $options?sep)[$options?useHeader]">
				<xsl:with-param name="options" tunnel="yes" select="$options"/>
			</xsl:apply-templates>
		</xsl:variable>
		<xsl:document>
			<xsl:element name="{$options?rootElement}">
				<xsl:apply-templates select="
						unparsed-text-lines($href)[if ($options?useHeader) then
							position() &gt; 1
						else
							true()]" mode="csv:rows">
					<xsl:with-param tunnel="yes" name="options" as="map(*)" select="map:merge((map{'header':$header}, $options))"/>
				</xsl:apply-templates>
			</xsl:element>
		</xsl:document>
	</xsl:function>
	
	<xsl:template match=".[. instance of xs:string]" mode="csv:rows">
		<xsl:param tunnel="yes" name="options"/>
		<xsl:element name="{$options?rowElement}">
			<xsl:apply-templates select="fn:tokenize(., $options?sep)" mode="csv:cells"/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match=".[. instance of xs:string]" mode="csv:cells">
		<xsl:param tunnel="yes" name="options"/>
		<xsl:variable name="pos" select="position()"/>
		<xsl:element name="{csv:header($pos, $options?header, $options?cellElement)}">
			<xsl:apply-templates mode="csv:cellValues" select="."/>
		</xsl:element>
	</xsl:template>
	
	<xsl:template match=".[. instance of xs:string]" mode="csv:cellValues" as="xs:string">
		<xsl:param tunnel="yes" name="options"/>
		<xsl:variable name="string-body-pattern"
                  as="xs:string"
                  select="'([^' || $options?quote || ']*)'"/>
    <xsl:variable name="quoted-value"
                  as="xs:string"
                  select="$options?quote 
                          || $string-body-pattern 
                          || $options?quote"/>
    <xsl:variable name="unquoted-value"
                  as="xs:string"
                  select="'(.+)'"/>
		<xsl:value-of select="replace(., 
                  $quoted-value || '|' || $unquoted-value, 
                  '$1$2')"/>
	</xsl:template>
	
	<xsl:function name="csv:csv-to-xml" as="document-node()">
		<xsl:param name="href" as="xs:anyURI"/>
		<xsl:sequence select="csv:csv-to-xml($href, ())"/>
	</xsl:function>
	
	<xsl:function name="csv:header" as="xs:string">
		<xsl:param name="col" as="xs:integer"/>
		<xsl:param name="header" as="xs:string*"/>
		<xsl:param name="cellElement" as="xs:string"/>
		<xsl:variable name="candidate" as="element()?">
			<xsl:try>
				<xsl:element name="{$header[$col]}"/>
				<xsl:catch>
					<xsl:element name="{$cellElement||$col}"/>
				</xsl:catch>
			</xsl:try>
		</xsl:variable>
		<xsl:value-of select="name($candidate)"/>
	</xsl:function>
	

</xsl:stylesheet>