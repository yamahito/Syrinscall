<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
  xmlns:csv="http://ns.expertml.com/csv/"
	xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
	exclude-result-prefixes="xs math xd csv"
	expand-text="yes"
	version="3.0">
	
	<xsl:import href="CSV.xslt"/>
	
	<xsl:param name="token" as="xs:string"/>
	<xsl:param name="csv-url" as="xs:anyURI"/>
	
	<xsl:variable name="csv-xml" select="csv:csv-to-xml($csv-url)"/>
	
	<xsl:output method="xhtml" html-version="5.0"/>
	
	<xsl:template name="xsl:initial-template">
		<html>
			<head>
				<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
				<meta name="viewport" content="width=1024, user-scalable=no"/>
				<title>Syrinscape Soundsets</title>
			</head>
			<body>
				<ul>
					<xsl:for-each-group select="$csv-xml/csv/row" group-by="soundset">
						<xsl:variable name="gid" select="generate-id(current-group()[1])"/>
						<li><a href="{$gid}.html"><xsl:value-of select="current-grouping-key()"/></a></li>
						<xsl:result-document href="{$gid}.html">
							<html>
								<head>
									<meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
									<meta name="viewport" content="width=1024, user-scalable=no"/>
									<title>{current-grouping-key()}</title>
								</head>
								<body>
									<iframe name="dummyframe" id="dummyframe" width="100%" height="300"/> <!--style="display: none"/>-->
    <form action="https://www.syrinscape.com/online/frontend-api/stop-all/" method="GET" target="dummyframe">
      <input type="hidden" name="auth_token" value="{$token}"/>
    	<div class="stop">
    		<button type="submit">Stop</button>
    	</div>
    	<div class="moods">
    		<ul>
    			<xsl:apply-templates select="current-group()[type='mood']"/>
    		</ul>
    	</div>
    	<div class="one-shots">
    		<ul>
    			<xsl:apply-templates select="current-group()[type='element'][sub_type='oneshot']"/>
    		</ul>
    	</div>
    </form>
								</body>
							</html>
						</xsl:result-document>
					</xsl:for-each-group>
				</ul>
			</body>
		</html>
	</xsl:template>
	
	<xsl:template match="row">
		<li><button formaction="{online_player_play_url}">{name}</button></li>
	</xsl:template>
		
	
</xsl:stylesheet>