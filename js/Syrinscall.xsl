<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
	xmlns:js="http://saxonica.com/ns/globalJS"
	xmlns:ejs="http://ns.expertml.com/saxonjs"
	xmlns:saxon="http://saxon.sf.net/"
	xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
	xmlns:html="http://www.w3.org/1999/xhtml"
	extension-element-prefixes="ixsl"
	expand-text="yes"
	version="3.0">
	
	<xsl:import href="Utils.xsl"/>
	
	<xsl:key name="byClass" match="*[@class]" use="tokenize(@class, '\s')"/>
	
	<xsl:template name="xsl:initial-template">
		<xsl:message>SaxonJS Initialised!</xsl:message>
	</xsl:template>
	
</xsl:stylesheet>