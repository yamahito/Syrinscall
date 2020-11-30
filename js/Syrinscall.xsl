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
	xmlns:local="http://ns.expertml.com/local"
	xmlns="http://www.w3.org/1999/xhtml"
	extension-element-prefixes="ixsl"
	expand-text="yes"
	version="3.0">
	
	<xsl:import href="Utils.xsl"/>
	
	<xsl:variable name="auth_token" select="ixsl:query-params()?auth_token"/>
	
	<xsl:template name="xsl:initial-template">
		<xsl:message>Using Auth Token: {$auth_token}</xsl:message>
		<xsl:call-template name="prepare_form"/>
	</xsl:template>
	
	<xsl:template name="prepare_form">
		<xsl:result-document href="#formcontrols">
			<input type="hidden" name="auth_token" value="{$auth_token}"/>
		</xsl:result-document>
	</xsl:template>
	
	<xsl:mode name="ixsl:onclick" on-multiple-match="use-last"/>
	
	<xsl:template match="html:button[@data-rid][ejs:contains-class(., 'play')]" mode="ixsl:onclick">
		<xsl:message>Playing {.} (ID:{@data-rid})</xsl:message>
	</xsl:template>
	
	<xsl:template match="html:button[@data-rid][ejs:contains-class(., 'play_mood')]" mode="ixsl:onclick">
		<xsl:sequence select="ejs:remove-class(../html:button[ejs:contains-class(., 'active_mood')], 'active_mood')"/>
		<xsl:sequence select="ejs:add-class(., 'active_mood')"/>
		<xsl:next-match/>
	</xsl:template>
	
	<xsl:template match="html:button[ejs:contains-class(.,'master_stop')]" mode="ixsl:onclick">
		<xsl:message>Stopping all sounds.</xsl:message>
		<xsl:sequence select="ejs:remove-class(//html:button[ejs:contains-class(., 'active_mood')], 'active_mood')"/>
	</xsl:template>
	
	<xsl:template name="renderMap">
		<xsl:context-item as="map(*)" use="required"/>
		<xsl:message>{serialize(., map{'method': 'json'})}</xsl:message>
	</xsl:template>
	
	<xsl:function name="local:get-type-from-id" as="xs:string">
		<xsl:param name="id" as="xs:string"/>
		<xsl:variable name="prefix" select="substring-before($id, ':')"/>
		<xsl:choose>
			<xsl:when test="$prefix = 'm'">
				<xsl:text>moods</xsl:text>
			</xsl:when>
			<xsl:when test="$prefix = 'e'">
				<xsl:text>elements</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="error((), 'Unrecognised ID format: '||$id)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	
	<xsl:function name="local:get-id-number" as="xs:string">
		<xsl:param name="id" as="xs:string"/>
		<xsl:sequence select="if (contains($id, ':')) then substring-after($id, ':') else error((), 'Unrecognised ID format: '||$id)"/>
	</xsl:function>
	
</xsl:stylesheet>