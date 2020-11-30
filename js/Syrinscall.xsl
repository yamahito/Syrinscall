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
	
	<xsl:variable name="auth_token" select="ixsl:query-params()?auth_token" as="xs:string?"/>
	
	<xsl:template name="xsl:initial-template">
		<xsl:choose>
			<xsl:when test="exists($auth_token)">
				<xsl:call-template name="prepare_form"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="toggle_settings"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:variable name="sets" select="tokenize(ixsl:query-params()?sets, '\+')" as="xs:string*"/>
		<xsl:for-each select="$sets">
			<xsl:result-document href="#ChosenSets">
				<xsl:call-template name="add_set">
					<xsl:with-param name="new_tag" select="."/>
				</xsl:call-template>
			</xsl:result-document>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="prepare_form">
		<xsl:message>Using Auth Token: {$auth_token}</xsl:message>
		<xsl:result-document href="#formcontrols">
			<input type="hidden" name="auth_token" value="{$auth_token}"/>
		</xsl:result-document>
		<ixsl:set-attribute name="value" select="$auth_token" object="id('update_auth', ixsl:page())"/>
	</xsl:template>
	
	<xsl:mode name="ixsl:onclick" on-multiple-match="use-last"/>
	
	<xsl:template match="html:div[@id = 'modal_close']" mode="ixsl:onclick">
		<xsl:call-template name="toggle_settings"></xsl:call-template>
	</xsl:template>
	
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
	
	<xsl:template match="html:button[@id='show_settings']" name="toggle_settings" mode="ixsl:onclick">
		<xsl:message>Toggling Setting Pane</xsl:message>
		<xsl:sequence select="ejs:toggle-class(id('settings', ixsl:page()), 'is-active')"/>
		<xsl:sequence select="ejs:toggle-class(ixsl:page()/html:html, 'is-clipped')"/>
	</xsl:template>
	
	<xsl:template match="html:a[ejs:contains-class(., 'tag')][ejs:contains-class(., 'is-delete')]" mode="ixsl:onclick">
		<xsl:variable name="control" select="ancestor::html:div[@class='control']" as="element(html:div)"/>
		<xsl:variable name="tags" select="id('ChosenSets')/html:div except $control" as="element(html:div)*"/>
		<xsl:variable name="removed_set" select="normalize-space(preceding-sibling::html:a)" as="xs:string"/>
		<xsl:message>Removed set is {$removed_set}</xsl:message>
		<xsl:variable name="existing_set" select="tokenize(id('setsParams')/@value, '\+')" as="xs:string*"/>
		<xsl:message>existing tags are {string-join($existing_set, ', ')}</xsl:message>
		<xsl:message>Removing tag {..}</xsl:message>
		<ixsl:set-attribute name="value" select="string-join($existing_set[. ne $removed_set], '+')" object="id('setsParams')"/>
		<xsl:result-document href="#ChosenSets" method="ixsl:replace-content">
			<xsl:copy-of select="$tags"/>
		</xsl:result-document>
	</xsl:template>
	
	<xsl:template match="html:button[@id='choose_set']" mode="ixsl:onclick">
		<xsl:variable name="new_tag" select="normalize-space(id('add_set'))[. ne '']" as="xs:string?"/>
		<!--<xsl:message>New tag is: {$new_tag}</xsl:message>-->
		<xsl:variable name="old_tags" select="(id('ChosenSets')/html:div/html:div/html:a ! normalize-space(.))[.ne '']" as="xs:string*"/>
		<!--<xsl:message>Old tags are: {string-join($old_tags, ', ')}</xsl:message>-->
		<xsl:if test="exists($new_tag[not(. = $old_tags)])">
			<xsl:message>Adding tag {$new_tag}</xsl:message>
			<xsl:result-document href="#ChosenSets">
				<xsl:call-template name="add_set">
					<xsl:with-param name="new_tag" select="$new_tag"/>
				</xsl:call-template>
			</xsl:result-document>
		<ixsl:set-attribute name="value" select="string-join(distinct-values(($new_tag, $old_tags)), '+')" object="id('setsParams')"/>
		</xsl:if>
	</xsl:template>
	
	<xsl:template name="add_set">
		<xsl:param name="new_tag" as="xs:string"/>
		<div class="control">
			<div class="tags has-addons">
				<a class="tag is-primary">{$new_tag}</a>
				<a class="tag is-delete"/>
			</div>
		</div>
	</xsl:template>
	
	<xsl:template match="html:button[@id='submit_settings']" mode="ixsl:onclick">
		<xsl:message>Saving...</xsl:message>
		<ixsl:set-property name="auth_token" select="id('update_auth')/@value" object="ixsl:page()"/>
		<xsl:message>auth_token set to {ixsl:query-params()?auth_token}</xsl:message>
		<xsl:call-template name="toggle_settings"/>
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