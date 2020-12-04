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
	xmlns:array="http://www.w3.org/2005/xpath-functions/array"
	xmlns="http://www.w3.org/1999/xhtml"
	extension-element-prefixes="ixsl"
	expand-text="yes"
	version="3.0">
	
	<!--
		Imports
	-->
	<xsl:import href="Utils.xsl"/>
	
	<!-- 
		Params
	-->
	<xsl:param name="falseAtRunTime" select="false()" as="xs:boolean"/>
	<xsl:param name="CORSproxy" select="'https://cors-yamahito.herokuapp.com'"/>
	
	<!--
		Variables
	-->
	<xsl:variable name="auth_token" select="ixsl:query-params()?auth_token" as="xs:string?"/>
	<xsl:variable name="sets" select="tokenize(ixsl:query-params()?sets, '\+')" as="xs:string*"/>
	
	<!-- 
		Named Templates 
	-->
	
	<!-- The initial template opens the setting pane if there is no auth_token set; it also populates the configured sound set IDs in the settings. -->
	<xsl:template name="xsl:initial-template">
		<xsl:choose>
			<xsl:when test="exists($auth_token)">
				<xsl:call-template name="prepare_form"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="toggle_settings"/>
			</xsl:otherwise>
		</xsl:choose>
		<xsl:for-each select="$sets">
			<xsl:result-document href="#ChosenSets">
				<xsl:call-template name="add_set">
					<xsl:with-param name="new_tag" select="."/>
				</xsl:call-template>
			</xsl:result-document>
		</xsl:for-each>
		<xsl:call-template name="populateMoods"/>		
	</xsl:template>
	
	<!-- prepare_form adds the auth_token to the main control panel form and settings page -->
	<xsl:template name="prepare_form">
		<xsl:message>Using Auth Token: {$auth_token}</xsl:message>
		<xsl:result-document href="#formcontrols">
			<input type="hidden" name="auth_token" value="{$auth_token}"/>
		</xsl:result-document>
		<ixsl:set-attribute name="value" select="$auth_token" object="id('update_auth', ixsl:page())"/>
	</xsl:template>
	
	<!-- Populate Moods -->
	<xsl:template name="populateMoods">
		<xsl:for-each select="$sets">
			<xsl:variable name="href" select="$CORSproxy||'https://www.syrinscape.com/online/frontend-api/soundsets/'||.||'/?auth_token='||$auth_token||'&amp;format=json'"/>
			<ixsl:schedule-action http-request="map{
					'method'	: 'get',
					'href'		: $href
				}">
				<xsl:call-template name="local:populateSet"/>
			</ixsl:schedule-action>
		</xsl:for-each>
	</xsl:template>
	
	<xsl:template name="local:populateSet">
		<xsl:context-item as="map(*)" use="required"/>
		<xsl:variable name="body" as="map(*)*" select="parse-json(.?body)"/>
		<xsl:variable name="href" select="$CORSproxy||'https://www.syrinscape.com/online/frontend-api/moods/?format=json&amp;auth_token='||$auth_token||'&amp;soundset__uuid='||$body?uuid"/>
		<xsl:result-document href="#Moods">
			<p class="menu-label">{$body?name}</p>
			<div id="s:{$body?id}"/>
		</xsl:result-document>
		<ixsl:schedule-action http-request="map{'method' : 'get', 'href' : $href}">
			<xsl:call-template name="local:addMoods">
				<xsl:with-param name="soundset" select="'s:'||$body?id"/>
			</xsl:call-template>
		</ixsl:schedule-action>
	</xsl:template>
	
	<xsl:template name="local:addElement">
		<xsl:context-item as="map(*)" use="required"/>
		<xsl:variable name="element" select="parse-json(.?body)" as="map(*)"/>
		<xsl:apply-templates select="$element" mode="local:element"/>
	</xsl:template>
	
	<xsl:template match=".[.?element_type eq 'music']" mode="local:element">
		<xsl:message>Adding Music element: {.?name}</xsl:message>
		<xsl:result-document href="#Music">
			<div class="card" id="e:{.?pk}">
				<div class="card-content">
					<div class="media">
						<div class="media-content">
							<p class="title is-6">{.?name}</p>
						</div>
					</div>
				</div>
				<footer class="card-footer"> </footer>
			</div>
		</xsl:result-document>
	</xsl:template>
	<xsl:template match=".[.?element_type eq 'oneshot']" mode="local:element">
		<xsl:message>Adding Oneshot element: {.?name}</xsl:message>
		<xsl:result-document href="#OneShots">
			<button type="submit" id="e:{.?pk}" class="play play_element" formaction="https://www.syrinscape.com/online/frontend-api/elements/{.?pk}/play/?format=json">{.?name}</button>
		</xsl:result-document>
	</xsl:template>
	<xsl:template match=".[.?element_type eq 'sfx']" mode="local:element">
		<xsl:message>Adding SFX element: {.?name}</xsl:message>
		<xsl:result-document href="#Elements">
			<div class="card" id="e:{.?pk}">
				<div class="card-content">
					<div class="media">
						<div class="media-content">
							<p class="title is-6">{.?name}</p>
						</div>
					</div>
				</div>
				<footer class="card-footer"> </footer>
			</div>
		</xsl:result-document>
	</xsl:template>
	
	<xsl:template name="local:addMoods">
		<xsl:context-item as="map(*)" use="required"/>
		<xsl:param name="soundset" as="xs:string"/>
		<xsl:variable name="moods" select="parse-json(.?body)" as="array(*)?"/>
		<xsl:variable name="mood_number" select="array:size($moods)" as="xs:integer"/>
		<xsl:message>Found {$mood_number} moods...</xsl:message>
		<xsl:iterate select="(1 to $mood_number)[$mood_number ge 1]">
			<xsl:param name="elements" select="()" as="xs:string*"/>
			<xsl:on-completion>
				<xsl:for-each select="$elements">
					<xsl:message>fetching element at {.}</xsl:message>
					<ixsl:schedule-action http-request="map{'method': 'get', 'href' : $CORSproxy||.||'?auth_token='||$auth_token}">
						<xsl:call-template name="local:addElement"/>
					</ixsl:schedule-action>
				</xsl:for-each>
			</xsl:on-completion>
			<xsl:variable name="id" select="$moods(.)?pk"/>
			<xsl:variable name="name" select="$moods(.)?name"/>
			<xsl:message>Adding mood: {$name}</xsl:message>
			<xsl:result-document href="#{$soundset}">
				<button type="submit" data-rid="m:{$id}" class="play play_mood" formaction="https://www.syrinscape.com/online/frontend-api/moods/{$id}/play/?format=json">{$name}</button>
			</xsl:result-document>
			<xsl:variable name="elems" select="$moods(.)?elements" as="array(*)"/>
			<xsl:variable name="elemURLs" as="xs:string*">
				<xsl:for-each select="(1 to array:size($elems))[array:size($elems) gt 1]">
					<xsl:sequence select="$elems(.)?element"/>
				</xsl:for-each>
			</xsl:variable>
			<xsl:next-iteration>
				<xsl:with-param name="elements" select="distinct-values(($elements, $elemURLs))"/>
			</xsl:next-iteration>
		</xsl:iterate>
	</xsl:template>
	
	<!-- Show/Hide Settings -->
	<xsl:template name="toggle_settings">
		<xsl:message>Toggling Setting Pane</xsl:message>
		<xsl:sequence select="ejs:toggle-class(id('settings', ixsl:page()), 'is-active')"/>
		<xsl:sequence select="ejs:toggle-class(ixsl:page()/html:html, 'is-clipped')"/>
	</xsl:template>
	
	<!-- Add Soundset Tag -->
	<xsl:template name="add_set">
		<xsl:param name="new_tag" as="xs:string"/>
		<xsl:variable name="old_tags" as="xs:string?" select="id('setsParams', ixsl:page())/@value"/>
		<div class="control">
			<div class="tags has-addons">
				<a class="tag is-primary">{$new_tag}</a>
				<a class="tag is-delete"/>
			</div>
		</div>
		<ixsl:set-attribute name="value" select="string-join(distinct-values((tokenize($old_tags, '\+'), $new_tag)), '+')" object="id('setsParams', ixsl:page())"/>
	</xsl:template>
	
	<!-- process_mood mode -->
	<xsl:mode name="process_mood" on-multiple-match="use-last"/>
	
	<xsl:template match=".[. instance of map(*)]" mode="process_mood">
		<xsl:message>{serialize(., map{'method':'json'})}</xsl:message>
	</xsl:template>
	
	<xsl:template match="html:iframe[@class='set_response']" mode="process_mood">
		<xsl:message>{./node()}</xsl:message>
	</xsl:template>
	
	
	<!-- 
		ixsl:onclick Mode
	-->
	<xsl:mode name="ixsl:onclick" on-multiple-match="use-last"/>
	
	<!-- Show/Hide Settings Pane -->
	<xsl:template match="html:button[@id= ('show_settings', 'modal_close')]" mode="ixsl:onclick">
		<xsl:call-template name="toggle_settings"/>
	</xsl:template>
	
	<!-- Logging play messages -->
	<xsl:template match="html:button[@data-rid][ejs:contains-class(., 'play')]" mode="ixsl:onclick">
		<xsl:message>Playing {.} (ID:{@data-rid})</xsl:message>
	</xsl:template>
	
	<!-- Playing Moods -->
	<xsl:template match="html:button[@data-rid][ejs:contains-class(., 'play_mood')]" mode="ixsl:onclick">
		<xsl:sequence select="ejs:remove-class(../html:button[ejs:contains-class(., 'active_mood')], 'active_mood')"/>
		<xsl:sequence select="ejs:add-class(., 'active_mood')"/>
		<xsl:next-match/>
	</xsl:template>
	
	<!-- Master Stop All sounds Button-->
	<xsl:template match="html:button[@id = 'master_stop']" mode="ixsl:onclick">
		<xsl:message>Stopping all sounds.</xsl:message>
		<xsl:sequence select="ejs:remove-class(//html:button[ejs:contains-class(., 'active_mood')], 'active_mood')"/>
	</xsl:template>
	
	<!-- Delete Soundset Tags Button-->
	<xsl:template match="html:a[ejs:contains-class(., 'tag')][ejs:contains-class(., 'is-delete')]" mode="ixsl:onclick">
		<xsl:variable name="control" select="ancestor::html:div[@class='control']" as="element(html:div)"/>
		<xsl:variable name="tags" select="id('ChosenSets')/html:div except $control" as="element(html:div)*"/>
		<xsl:variable name="removed_set" select="normalize-space(preceding-sibling::html:a)" as="xs:string"/>
		<xsl:variable name="existing_set" select="tokenize(id('setsParams')/@value, '\+')" as="xs:string*"/>
		<ixsl:set-attribute name="value" select="string-join($existing_set[. ne $removed_set], '+')" object="id('setsParams')"/>
		<xsl:result-document href="#ChosenSets" method="ixsl:replace-content">
			<xsl:copy-of select="$tags"/>
		</xsl:result-document>
	</xsl:template>
	
	<!-- Add Soundset Tags Button-->
	<xsl:template match="html:button[@id='choose_set']" mode="ixsl:onclick">
		<xsl:variable name="new_tag" select="normalize-space(id('add_set'))[. ne '']" as="xs:string?"/>
		<xsl:variable name="old_tags" select="(id('ChosenSets')/html:div/html:div/html:a ! normalize-space(.))[.ne '']" as="xs:string*"/>
		<xsl:if test="exists($new_tag[not(. = $old_tags)])">
			<xsl:message>Adding tag {$new_tag}</xsl:message>
			<xsl:result-document href="#ChosenSets">
				<xsl:call-template name="add_set">
					<xsl:with-param name="new_tag" select="$new_tag"/>
				</xsl:call-template>
			</xsl:result-document>
		</xsl:if>
	</xsl:template>
	
	<!-- Submit Settings Button-->
	<xsl:template match="html:button[@id='submit_settings']" mode="ixsl:onclick">
		<xsl:message>Saving...</xsl:message>
		<ixsl:set-property name="auth_token" select="id('update_auth')/@value" object="ixsl:page()"/>
		<xsl:message>auth_token set to {ixsl:query-params()?auth_token}</xsl:message>
		<xsl:call-template name="toggle_settings"/>
	</xsl:template>
	
	<!-- 
		Functions
	-->
	
	<!-- Gets type from id prefixes -->
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
	<!-- Gets number from prefexed ids -->
	<xsl:function name="local:get-id-number" as="xs:string">
		<xsl:param name="id" as="xs:string"/>
		<xsl:sequence select="if (contains($id, ':')) then substring-after($id, ':') else error((), 'Unrecognised ID format: '||$id)"/>
	</xsl:function>
	
</xsl:stylesheet>