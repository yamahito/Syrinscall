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
	xmlns:map="http://www.w3.org/2005/xpath-functions/map"
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
	<xsl:param name="CORSproxy" select="(ixsl:query-params()?cors, 'https://cors-yamahito.herokuapp.com/')[1]"/>
	
	<!--
		Variables
	-->
	<xsl:variable name="auth_token" select="ixsl:query-params()?auth_token" as="xs:string?"/>
	<xsl:variable name="sets" select="tokenize(ixsl:query-params()?sets, '\+')" as="xs:string*"/>
	<xsl:variable name="elems" select="tokenize(ixsl:query-params()?elems, '\+')" as="xs:string*"/>
	<xsl:variable name="moods" select="tokenize(ixsl:query-params()?moods, '\+')" as="xs:string*"/>
	
	<!--
		Keys
	-->
	<xsl:key name="byClass" match="*[@class]" use="tokenize(@class, '\s+')"/>
	
	
	<!-- 
		Named Templates 
	-->
	
	<!-- The initial template opens the setting pane if there is no auth_token set; it also populates the configured sound set IDs in the settings. -->
	<xsl:template name="xsl:initial-template">
		<xsl:message>using CORS proxy at {$CORSproxy}</xsl:message>
		<xsl:result-document href="#settingsForm">
			<input type="hidden" name="cors" value="{$CORSproxy}"/>
		</xsl:result-document>
		<xsl:choose>
			<xsl:when test="exists($auth_token)">
				<xsl:call-template name="prepare_form"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="toggle_settings"/>
			</xsl:otherwise>
		</xsl:choose>
		<ixsl:schedule-action http-request="map{     'method' : 'get',     'href'   : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/state/?auth_token='||$auth_token    }">
			<xsl:call-template name="ejs:handle-response">
				<xsl:with-param name="action" select="xs:QName('local:populate')"/>
			</xsl:call-template>
		</ixsl:schedule-action>
	</xsl:template>
	
	<!-- Populate using Current Mood -->
	<xsl:template match=".[. eq xs:QName('local:populate')]" mode="ejs:action">
		<xsl:param name="response" tunnel="yes" as="map(*)"/>
		<xsl:for-each select="$sets">
			<!-- Add Soundsets -->
			<ixsl:schedule-action http-request="map{
					'method'	: 'get',
					'href'		: $CORSproxy||'https://www.syrinscape.com/online/frontend-api/soundsets/'||.||'/?auth_token='||$auth_token
				}">
				<xsl:call-template name="ejs:handle-response">
					<xsl:with-param name="action" select="xs:QName('local:addSet')"/>
					<xsl:with-param name="state" tunnel="true" select="$response"/>
				</xsl:call-template>
			</ixsl:schedule-action>
			<xsl:result-document href="#ChosenSets">
				<xsl:call-template name="add_set_tag">
					<xsl:with-param name="new_tag" select="."/>
				</xsl:call-template>
			</xsl:result-document>
		</xsl:for-each>
		<xsl:for-each select="$elems">
			<ixsl:schedule-action http-request="map{
				'method': 'get',
				'href' : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/elements/'||.||'/?auth_token='||$auth_token}">
				<xsl:call-template name="ejs:handle-response">
					<xsl:with-param name="action" select="xs:QName('local:addElement')"/>
					<xsl:with-param name="pinned" tunnel="yes" select="true()"/>
					<xsl:with-param name="state" tunnel="true" select="$response"/>
				</xsl:call-template>
			</ixsl:schedule-action>
			<xsl:result-document href="#ChosenElems">
				<xsl:call-template name="add_elem_tag">
					<xsl:with-param name="new_tag" select="."/>
				</xsl:call-template>
			</xsl:result-document>
		</xsl:for-each>
		<xsl:if test="exists($moods)">
			<xsl:result-document href="#Moods">
				<p class="menu-label mood-title">Selected Moods<a class="hide-moods"><i class="collapse"></i>
</a></p>
			<div id="s:custom"/>
			</xsl:result-document>
		</xsl:if>
		<xsl:for-each select="$moods">
			<ixsl:schedule-action http-request="map{
				'method':	'get',
				'href':	$CORSproxy||'https://www.syrinscape.com/online/frontend-api/moods/'||.||'/?auth_token='||$auth_token}">
				<xsl:call-template name="ejs:handle-response">
					<xsl:with-param name="action" select="xs:QName('local:addMood')"/>
					<xsl:with-param name="state" tunnel="true" select="$response"/>
					<xsl:with-param name="soundset" tunnel="true" select="'custom'"/>
				</xsl:call-template>
			</ixsl:schedule-action>
			<xsl:result-document href="#ChosenMoods">
				<xsl:call-template name="add_mood_tag">
					<xsl:with-param name="new_tag" select="."/>
				</xsl:call-template>
			</xsl:result-document>
		</xsl:for-each>
	</xsl:template>
	
	<!-- prepare_form adds the auth_token to the main control panel form and settings page -->
	<xsl:template name="prepare_form">
		<xsl:message>Using Auth Token: {$auth_token}</xsl:message>
		<xsl:result-document href="#formcontrols">
			<input type="hidden" name="auth_token" value="{$auth_token}"/>
		</xsl:result-document>
		<ixsl:set-attribute name="value" select="$auth_token" object="id('update_auth', ixsl:page())"/>
	</xsl:template>
	
	<!-- Adding Soundsets -->
	<xsl:mode name="local:addSet"/>
	
	<xsl:template match=".[. eq xs:QName('local:addSet')]" mode="ejs:action">
		<xsl:param name="response" tunnel="yes"/>
		<xsl:variable name="href" select="$CORSproxy||'https://www.syrinscape.com/online/frontend-api/moods/?format=json&amp;auth_token='||$auth_token||'&amp;soundset__uuid='||$response?uuid"/>
		<xsl:result-document href="#Moods">
			<p class="menu-label mood-title">{$response?name}<a class="hide-moods"><i class="collapse"></i>
</a></p>
			<div id="s:{$response?id}"/>
		</xsl:result-document>
		<ixsl:schedule-action http-request="map{'method' : 'get', 'href' : $href}">
			<xsl:call-template name="ejs:handle-response">
				<xsl:with-param name="action" select="xs:QName('local:addMoods')"/>
				<xsl:with-param name="soundset" select="'s:'||$response?id" tunnel="yes"/>
				<xsl:with-param name="uuid" tunnel="yes" select="$response?uuid"/>
			</xsl:call-template>
		</ixsl:schedule-action>
	</xsl:template>
	
	<!-- Adding Soundset Moods -->
	<xsl:template match=".[. eq xs:QName('local:addMoods')]" mode="ejs:action">
		<xsl:param name="response" tunnel="yes" as="array(*)?"/>
		<xsl:param name="soundset" as="xs:string" tunnel="yes"/>
		<xsl:param name="uuid" tunnel="yes"/>
		<xsl:param name="state" tunnel="yes"/>
		<xsl:variable name="current_mood" select="string($state?mixpanel-current-mood?pk)"/>
		<xsl:variable name="mood_number" select="array:size($response)" as="xs:integer"/>
		<xsl:message>Found {$mood_number} moods...</xsl:message>
		<xsl:iterate select="(1 to $mood_number)">
			<xsl:param name="in-mood" select="()" as="xs:string*"/>
			<xsl:on-completion>
				<ixsl:schedule-action http-request="map{
					'method': 'get',
					'href':  $CORSproxy||'https://www.syrinscape.com/online/frontend-api/elements/?format=json&amp;auth_token='||$auth_token||'&amp;soundset__uuid='||$uuid
					}">
					<xsl:call-template name="ejs:handle-response">
						<xsl:with-param name="action" select="xs:QName('local:addMoodElements')"/>
						<xsl:with-param name="in-mood" select="$in-mood" tunnel="yes"/>
					</xsl:call-template>
				</ixsl:schedule-action>
			</xsl:on-completion>
			<xsl:variable name="this.mood" select="$response(.)"/>
			<xsl:variable name="id" select="string($this.mood?pk)"/>
			<xsl:variable name="name" select="$this.mood?name"/>
			<xsl:message>Adding mood: {$name}</xsl:message>
			<xsl:variable name="local.elems" as="map(*)*">
				<xsl:for-each select="(1 to array:size($this.mood?elements))">
					<xsl:variable name="this.element" select="$this.mood?elements(.)"/>
					<xsl:variable name="url" select="$this.element?element"/>
					<xsl:variable name="pk-string" as="xs:string?" select="replace($url, 'https://www.syrinscape.com/online/frontend-api/elements/(\d+)/', '$1')"/>
					<xsl:map>
						<xsl:map-entry key="'pk'" select="$pk-string"/>
						<xsl:map-entry key="'id'" select="'e:'||$pk-string"/>
						<xsl:map-entry key="'url'" select="$url"/>
						<xsl:map-entry key="'plays'" select="$this.element?plays"/> 
					</xsl:map>
				</xsl:for-each>
			</xsl:variable>
			<xsl:result-document href="#{$soundset}">
				<button type="button" id="m:{$id}" data-elements="{string-join($local.elems[.?plays]?id, ' ')}" class="{'is-playing '[$id eq $current_mood]}play play_mood">{$name}</button>
			</xsl:result-document>
			<xsl:next-iteration>
				<xsl:with-param name="in-mood" select="distinct-values(($in-mood, ($local.elems[.?plays]?pk)[$id eq $current_mood]))"/>
			</xsl:next-iteration>
		</xsl:iterate>
	</xsl:template>

	<!-- Adding Individual Moods -->
	<xsl:template match=".[. eq xs:QName('local:addMood')]" mode="ejs:action">
		<xsl:param name="response" tunnel="yes" as="map(*)?"/>
		<xsl:param name="soundset" as="xs:string" tunnel="yes"/>
		<xsl:param name="state" tunnel="yes"/>
		<xsl:variable name="this.mood" select="$response"/>
		<xsl:variable name="current_mood" select="string($state?mixpanel-current-mood?pk)"/>
		<xsl:variable name="mood.id" select="string($this.mood?pk)"/>
		<xsl:variable name="name" select="$this.mood?name"/>
		<xsl:message>Adding individual mood: {$name}</xsl:message>
		<xsl:variable name="local.elems" as="map(*)*">
			<xsl:for-each select="(1 to array:size($this.mood?elements))">
				<xsl:variable name="this.element" select="$this.mood?elements(.)"/>
				<xsl:variable name="url" select="$this.element?element"/>
				<xsl:variable name="pk-string" as="xs:string?" select="replace($url, 'https://www.syrinscape.com/online/frontend-api/elements/(\d+)/', '$1')"/>
				<xsl:map>
					<xsl:map-entry key="'pk'" select="$pk-string"/>
					<xsl:map-entry key="'id'" select="'e:' || $pk-string"/>
					<xsl:map-entry key="'url'" select="$url"/>
					<xsl:map-entry key="'plays'" select="$this.element?plays"/>
				</xsl:map>
			</xsl:for-each>
		</xsl:variable>
		<xsl:for-each select="$local.elems">
			<xsl:variable name="elem" select="." as="map(*)"/>
			<ixsl:schedule-action http-request="map{
				'method': 'get',
				'href':  $CORSproxy||$elem?url||'?format=json&amp;auth_token='||$auth_token    }">
				<xsl:call-template name="ejs:handle-response">
					<xsl:with-param name="action" select="xs:QName('local:addElement')"/>
					<xsl:with-param name="in-mood" select="$elem?pk[$mood.id eq $current_mood]" tunnel="yes"/>
				</xsl:call-template>
			</ixsl:schedule-action>
		</xsl:for-each>
		<xsl:result-document href="#s:{$soundset}">
			<button type="button" id="m:{$response?pk}" data-elements="{string-join($local.elems[.?plays]?id, ' ')}" class="{'is-playing '[$mood.id eq $current_mood]}play play_mood">{$name}</button>
		</xsl:result-document>
	</xsl:template>

	<!-- Adding Elements from Mood -->
	<xsl:template match=".[. eq xs:QName('local:addMoodElements')]" mode="ejs:action">
		<xsl:param name="response" tunnel="yes"/>
		<xsl:for-each select="(1 to array:size($response))">
			<xsl:apply-templates select="$response(.)" mode="local:addElement"/>			
		</xsl:for-each>
	</xsl:template>
		
	<!-- Adding Elements -->
	<xsl:mode name="local:addElement" on-multiple-match="use-last"/>
	
	<xsl:template match=".[. eq xs:QName('local:addElement')]" mode="ejs:action">
		<xsl:param name="response" tunnel="yes"/>
		<xsl:apply-templates select="$response" mode="local:addElement"/>
	</xsl:template>
	
	<xsl:template match=".[.?element_type eq 'music']" mode="local:addElement">
		<xsl:param name="pinned" as="xs:boolean" select="false()" tunnel="yes"/>
		<xsl:param name="in-mood" tunnel="yes" as="xs:string*"/>
		<xsl:param name="state" tunnel="yes"/>
		<xsl:variable name="pk" select="xs:integer(.?pk)" as="xs:integer"/>
		<xsl:variable name="id" select="'e:'||$pk"/>
		<xsl:variable name="in-current-mood" select="string($pk) = $in-mood" as="xs:boolean"/>
		<xsl:if test="not(exists(id($id, ixsl:page())))">
			<xsl:message>Adding Music element: {.?name}, {$id}</xsl:message>
			<xsl:result-document href="#Music">
				<div data-rid="{$id}" class="{string-join(('column', 'is-hidden'[not($pinned or $in-current-mood)], 'is-pinned'[$pinned], 'is-playing'[$state('element')(string($pk))?is_playing]), ' ')}">
					<div class="music-element element card" id="{$id}">
						<div class="card-content">
							<div class="media">
								<div class="media-left">
									<span class="icon is-medium">
										<i class="fas fa-lg fa-music"/>
									</span>
								</div>
								<div class="media-content">
									<p class="title is-6">{.?name}</p>
									<p class="subtitle is-6">{$id}</p>
								</div>
							</div>
						</div>
						<a class="pin">
							<span class="icon">
								<i class="pin_icon"/>
							</span>
						</a>
						<xsl:call-template name="card-footer"/>
					</div>
				</div>
			</xsl:result-document>
		</xsl:if>
		<xsl:on-empty>
			<xsl:message>Skipping Music element {.?name}, already added.</xsl:message>
		</xsl:on-empty>
	</xsl:template>
	<xsl:template match=".[.?element_type eq 'oneshot']" mode="local:addElement">
		<xsl:variable name="pk" select="xs:integer(.?pk)" as="xs:integer"/>
		<xsl:if test="not(exists(id('e:' || $pk, ixsl:page())))">
			<xsl:message>Adding Oneshot element: {.?name}</xsl:message>
			<xsl:result-document href="#OneShots">
				<button type="button" id="e:{$pk}" class="play play_element">{.?name}</button>
			</xsl:result-document>
		</xsl:if>
		<xsl:on-empty>
			<xsl:message>Skipping Oneshot element {.?name}, already added.</xsl:message>
		</xsl:on-empty>
	</xsl:template>
	<xsl:template match=".[.?element_type eq 'sfx']" mode="local:addElement">
		<xsl:param name="pinned" as="xs:boolean" select="false()" tunnel="yes"/>
		<xsl:param name="in-mood" tunnel="yes" as="xs:string*"/>
		<xsl:param name="state" tunnel="yes"/>
		<xsl:variable name="pk" select="xs:integer(.?pk)" as="xs:integer"/>
		<xsl:variable name="id" select="'e:'||$pk"/>
		<xsl:variable name="in-current-mood" select="string($pk) = $in-mood"/>
		<xsl:if test="not(exists(id($id, ixsl:page())))">
			<xsl:message>Adding SFX element: {.?name}</xsl:message>
			<xsl:result-document href="#Elements">
				<div data-rid="{$id}" class="{string-join(('column', 'is-hidden'[not($pinned or $in-current-mood)], 'is-pinned'[$pinned], 'is-playing'[$state('element')(string($pk))?is_playing]), ' ')}">
					<div class="sfx-element element card" id="e:{$pk}">
						<div class="card-content">
							<div class="media">
								<div class="media-left">
									<span class="icon is-medium">
										<i class="fas fa-lg fa-volume-up"/>
									</span>
								</div>
								<div class="media-content">
									<p class="title is-6">{.?name}</p>
									<p class="subtitle is-6">e:{$pk}</p>
								</div>
							</div>
						</div>
						<a class="pin">
							<span class="icon">
								<i class="pin_icon"/>
							</span>
						</a>
						<xsl:call-template name="card-footer"/>
					</div>
				</div>
			</xsl:result-document>
		</xsl:if>
		<xsl:on-empty>
			<xsl:message>Skipping SFX element {.?name}, already added.</xsl:message>
		</xsl:on-empty>
	</xsl:template>
	
	<xsl:template name="card-footer">
		<xsl:variable name="pk" select="xs:integer(.?pk)"/>
		<footer class="card-footer">
			<div id="e:{$pk}-play" class="card-control play">
				<a id="e:{$pk}-play-button" class="play-button">
					<i class="play-pause"/>
				</a>
			</div>
			<div id="e:{$pk}-volume" class="card-control volume">
				<div class="volume-number">
					<input id="e:{$pk}-volume-number" autocomplete="off" data-rid="e:{$pk}" class="input" type="number" min="0" max="100" step="1" value="{(xs:integer(100 * .?initial_volume), 100)[1]}"/>
				</div>
				<div class="volume-slider">
					<input id="e:{$pk}-volume-slider" autocomplete="off" data-rid="e:{$pk}" class="slider" type="range" min="0" max="100" step="1" value="{(xs:integer(100 * .?initial_volume), 100)[1]}"/>
				</div>
			</div>
		</footer>
	</xsl:template>
	
	<!-- Show/Hide Settings -->
	<xsl:template name="toggle_settings">
		<xsl:message>Toggling Setting Pane</xsl:message>
		<xsl:sequence select="ejs:toggle-class(id('settings', ixsl:page()), 'is-active')"/>
		<xsl:sequence select="ejs:toggle-class(ixsl:page()/html:html, 'is-clipped')"/>
	</xsl:template>
	
	<!-- Add Soundset Tag -->
	<xsl:template name="add_set_tag">
		<xsl:param name="new_tag" as="xs:string"/>
		<xsl:variable name="old_tags" as="xs:string?" select="id('setsParams', ixsl:page())/@value"/>
		<xsl:result-document href="#ChosenSets">
			<div class="control" data-rid="s:{$new_tag}" id="s:{$new_tag}-tag">
				<div class="tags has-addons">
					<span class="tag is-primary">{$new_tag}</span>
					<a class="tag is-delete"/>
				</div>
			</div>
		</xsl:result-document>
		<ixsl:set-attribute name="value" select="string-join(distinct-values((tokenize($old_tags, '\+'), $new_tag)), '+')" object="id('setsParams', ixsl:page())"/>
	</xsl:template>
	
	<!-- Add Mood Tag -->
	<xsl:template name="add_mood_tag">
		<xsl:param name="new_tag" as="xs:string"/>
		<xsl:variable name="old_tags" as="xs:string?" select="id('moodsParams', ixsl:page())/@value"/>
		<xsl:result-document href="#ChosenMoods">
			<div class="control" data-rid="e:{$new_tag}" id="e:{$new_tag}-tag">
				<div class="tags has-addons">
					<span class="tag is-primary">{$new_tag}</span>
					<a class="tag is-delete"/>
				</div>					
			</div>
		</xsl:result-document>
		<ixsl:set-attribute name="value" select="string-join(distinct-values((tokenize($old_tags, '\+'), $new_tag)), '+')" object="id('moodsParams', ixsl:page())"/>
	</xsl:template>
	
	<!-- Add Element Tag -->
	<xsl:template name="add_elem_tag">
		<xsl:param name="new_tag" as="xs:string"/>
		<xsl:variable name="old_tags" as="xs:string?" select="id('elemsParams', ixsl:page())/@value"/>
		<xsl:result-document href="#ChosenElems">
			<div class="control" data-rid="e:{$new_tag}" id="e:{$new_tag}-tag">
				<div class="tags has-addons">
					<span class="tag is-primary">{$new_tag}</span>
					<a class="tag is-delete"/>
				</div>
			</div>
		</xsl:result-document>
		<ixsl:set-attribute name="value" select="string-join(distinct-values((tokenize($old_tags, '\+'), $new_tag)), '+')" object="id('elemsParams', ixsl:page())"/>
	</xsl:template>
	
	<!-- Refresh state -->
	<xsl:template name="refresh_state">
		<ixsl:schedule-action http-request="map{
				'method' : 'get',
				'headers': map{
					'Cache-Control': 'no-store'
					},
				'href'   : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/state/?format=json&amp;unique='||js:Date.now()||'&amp;auth_token='||$auth_token
			}">
			<xsl:call-template name="ejs:handle-response">
				<xsl:with-param name="action" select="xs:QName('local:status')"/>
			</xsl:call-template>
		</ixsl:schedule-action>
	</xsl:template>
	
	<!-- status mode -->
	<xsl:mode name="local:status" on-no-match="shallow-skip" on-multiple-match="use-last"/>
	
	<xsl:template match=".[. eq xs:QName('local:status')]" mode="ejs:action">
		<xsl:param name="response" as="map(*)" tunnel="yes"/>
		<xsl:variable name="current-mood" as="xs:string?" select="string($response?mixpanel-current-mood?pk)"/>
		<xsl:sequence select="
			local:set-volume('master', $response?global?volume, 1.5),
			local:set-volume('oneshot', $response?global?oneshot_volume)
			"/>
		<xsl:apply-templates select="id('main', ixsl:page())/*" mode="local:status"/>
	</xsl:template>
	
	<xsl:template match="html:button[ejs:contains-class(., 'play_mood')]" mode="local:status">
		<xsl:param name="response" as="map(*)" tunnel="yes"/>
		<xsl:variable name="pk" as="xs:string" select="local:get-id-number(@id)"/>
		<xsl:variable name="playing" as="xs:boolean" select="($response?mood?($pk)?is_playing, false())[1]"/>
		<xsl:message>getting status of mood {$pk}</xsl:message>
		<xsl:message>ejs:contains-class(., 'play_mood') is {ejs:contains-class(., 'play_mood')}</xsl:message>
		<xsl:message>Mood playing: {$playing}</xsl:message>
		<!-- Update mood -->
		<xsl:choose>
			<xsl:when test="$playing">
				<xsl:sequence select="ejs:add-class(., 'is-playing')"/>
				<xsl:message>Mood {@id} playing</xsl:message>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="ejs:remove-class(., 'is-playing')"/>
				<xsl:message>Mood {@id} not playing</xsl:message>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
		
	<xsl:template match="html:div[@id=('Music', 'Elements')]/html:div" mode="local:status">
		<xsl:param name="response" as="map(*)" tunnel="yes"/>
		<xsl:variable name="pk" select="local:get-id-number(@data-rid)"/>
		<xsl:choose>
			<xsl:when test="$response('element')($pk)?is_playing">
				<!-- Element plays in mood -->
				<xsl:sequence select="
					ejs:remove-class(., 'is-hidden'),
					local:set-volume(@data-rid, ($response('element')($pk)?vol, id(@data-rid||'-volume-number')/@value div 100, 0)[1]),
					ejs:add-class(., 'is-playing')"/>
			</xsl:when>
			<xsl:when test="ejs:contains-class(., 'is-pinned')">
				<!-- Element does not play in mood, but is pinned -->
				<xsl:sequence select="ejs:remove-class(., 'is-playing')"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- Element does not play in mood, is not pinned -->
				<xsl:sequence select="ejs:add-class(., 'is-hidden'), ejs:remove-class(., 'is-playing')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<!--
		ixsl:onchange Mode
	-->
	<xsl:mode name="ixsl:onchange" on-multiple-match="use-last"/>
	
	<!-- adjust volume -->
	<xsl:template match="html:input[@data-rid][ends-with(@id, '-volume-number') or ends-with(@id, '-volume-slider')]" mode="ixsl:onchange">
		<xsl:param name="vol" as="xs:double"/>
		<xsl:message>Setting volume of element {@data-rid}</xsl:message>
		<ixsl:schedule-action http-request="map{
				'method': 'post',
				'href'  : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/elements/'||local:get-id-number(@data-rid)||'/set_current_volume/?auth_token='||$auth_token,
				'body'  : serialize(map{'current_volume': $vol}, map{'method':'json'}),
				'media-type' : 'application/json'
			}">
			<xsl:call-template name="refresh_state"/>
		</ixsl:schedule-action>
	</xsl:template>
	<xsl:template match="html:input[starts-with(@data-rid, 'master')][ends-with(@id, '-volume-number') or ends-with(@id, '-volume-slider')]" mode="ixsl:onchange">
		<xsl:param name="vol" as="xs:double"/>
		<xsl:message>Setting volume of master {@data-rid}</xsl:message>
		<ixsl:schedule-action http-request="map{
				'method': 'patch',
				'href'  : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/state/global/?auth_token='||$auth_token,
				'body'  : serialize(map{'volume': $vol}, map{'method':'json'}),
				'media-type' : 'application/json'
			}">
			<xsl:call-template name="refresh_state"/>
		</ixsl:schedule-action>
	</xsl:template>
	<xsl:template match="html:input[starts-with(@data-rid, 'oneshot')][ends-with(@id, '-volume-number') or ends-with(@id, '-volume-slider')]" mode="ixsl:onchange">
		<xsl:param name="vol" as="xs:double"/>
		<xsl:message>Setting volume of oneshots {@data-rid}</xsl:message>
		<ixsl:schedule-action http-request="map{
				'method': 'patch',
				'href'  : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/state/global/?auth_token='||$auth_token,
				'body'  : serialize(map{'oneshot_volume': $vol}, map{'method':'json'}),
				'media-type' : 'application/json'
			}">
			<xsl:call-template name="refresh_state"/>
		</ixsl:schedule-action>
	</xsl:template>
	
	<xsl:template match="html:input[@data-rid][ends-with(@id, '-volume-number') or ends-with(@id, '-volume-slider')]" mode="ixsl:onchange">
		<xsl:variable name="vol" select="(ixsl:get(ixsl:event(), 'target.value') div 100, @value div 100, 0)[1]" as="xs:double"/>
		<xsl:sequence select="local:set-volume(@data-rid, $vol, @max div 100)"/>
		<xsl:next-match>
			<xsl:with-param name="vol" select="$vol"/>
		</xsl:next-match>
	</xsl:template>
	
	<!-- 
		ixsl:onclick Mode
	-->
	<xsl:mode name="ixsl:onclick" on-multiple-match="use-last"/>
	
	<!-- Show/Hide Settings Pane -->
	<xsl:template match="html:button[@id = ('show_settings')]|html:div[@id = ('modal_close')]" mode="ixsl:onclick">
		<xsl:call-template name="toggle_settings"/>
	</xsl:template>
	
	<!-- Logging play messages -->
	<xsl:template match="html:button[ejs:contains-class(., 'play_mood')]" mode="ixsl:onclick">
		<xsl:sequence select="ejs:add-class(., 'is-playing')"/>
		<ixsl:schedule-action http-request="map{
				'method'	: 'get',
				'href'		:	 $CORSproxy||'https://www.syrinscape.com/online/frontend-api/moods/'||local:get-id-number(@id)||'/play/?format=json'||'&amp;auth_token='||$auth_token
			}">
			<xsl:call-template name="ejs:handle-response">
				<xsl:with-param name="action" select="xs:QName('local:play-mood')"/>
			</xsl:call-template>
		</ixsl:schedule-action>
	</xsl:template>
	<xsl:template match="html:button[ejs:contains-class(., 'play_element')]" mode="ixsl:onclick">
	 <ixsl:schedule-action http-request="map{
	 		'method'	:	'get',
	 		'href'		:	 $CORSproxy||'https://www.syrinscape.com/online/frontend-api/elements/'||local:get-id-number(@id)||'/play/?format=json'||'&amp;auth_token='||$auth_token
	 	}">
	 	<xsl:call-template name="ejs:handle-response">
	 		<xsl:with-param name="action" select="xs:QName('local:play-oneshot')"/>
	 	</xsl:call-template>
	 </ixsl:schedule-action>
	</xsl:template>
	<xsl:template match="html:button[ejs:contains-class(., 'play')]" mode="ixsl:onclick">
		<xsl:message>Playing {.} (ID:{@id})</xsl:message>
		<xsl:next-match/>
	</xsl:template>
	
	<!-- Refresh Button -->
	<xsl:template match="html:button[@id='refresh']" mode="ixsl:onclick">
		<xsl:call-template name="refresh_state"/>
	</xsl:template>
	
	<!-- Master Stop All sounds Button-->
	<xsl:template match="html:button[@id = 'master_stop']" mode="ixsl:onclick">
		<xsl:message>Stopping all sounds.</xsl:message>
		<ixsl:schedule-action http-request="map{
				'method'	:	'get',
				'href'		:	$CORSproxy||'https://www.syrinscape.com/online/frontend-api/stop-all'||'/?auth_token='||$auth_token
			}">
			<xsl:call-template name="ejs:handle-response">
				<xsl:with-param name="action" select="xs:QName('local:master_stop')"/>
			</xsl:call-template>
		</ixsl:schedule-action>
	</xsl:template>
	
	<!-- Delete Soundset/Element Tags Button-->
	<xsl:template match="html:a[ejs:contains-class(., 'tag')][ejs:contains-class(., 'is-delete')]" mode="ixsl:onclick">
		<xsl:variable name="control" select="ancestor::html:div[@class='control']" as="element(html:div)"/>
		<xsl:variable name="Chosen" select="ancestor::html:div[@id=('ChosenSets', 'ChosenElems', 'ChosenMoods')]"/>
		<xsl:variable name="tags" select="$Chosen/html:div except $control" as="element(html:div)*"/>
		<xsl:variable name="removed_set" select="normalize-space(preceding-sibling::html:span)" as="xs:string"/>
		<xsl:variable name="input" select="$Chosen/following-sibling::html:input[1]"/>
		<xsl:variable name="existing_set" select="tokenize($input/@value, '\+')" as="xs:string*"/>
		<ixsl:set-attribute name="value" select="string-join($existing_set[. ne $removed_set], '+')" object="$input"/>
		<xsl:result-document href="#{$Chosen/@id}" method="ixsl:replace-content">
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
				<xsl:call-template name="add_set_tag">
					<xsl:with-param name="new_tag" select="$new_tag"/>
				</xsl:call-template>
			</xsl:result-document>
		</xsl:if>
	</xsl:template>
	
	<!-- Add Moods Tags Button-->
	<xsl:template match="html:button[@id='choose_mood']" mode="ixsl:onclick">
		<xsl:variable name="new_tag" select="normalize-space(id('add_mood'))[. ne '']" as="xs:string?"/>
		<xsl:variable name="old_tags" select="(id('ChosenMoods')/html:div/html:div/html:a ! normalize-space(.))[.ne '']" as="xs:string*"/>
		<xsl:if test="exists($new_tag[not(. = $old_tags)])">
			<xsl:message>Adding tag {$new_tag}</xsl:message>
			<xsl:result-document href="#ChosenMoods">
				<xsl:call-template name="add_mood_tag">
					<xsl:with-param name="new_tag" select="$new_tag"/>
				</xsl:call-template>
			</xsl:result-document>
		</xsl:if>
	</xsl:template>
	
	<!-- Add Element Tags Button-->
	<xsl:template match="html:button[@id='choose_elem']" mode="ixsl:onclick">
		<xsl:variable name="new_tag" select="normalize-space(id('add_elem'))[. ne '']" as="xs:string?"/>
		<xsl:variable name="old_tags" select="(id('ChosenElems')/html:div/html:div/html:a ! normalize-space(.))[.ne '']" as="xs:string*"/>
		<xsl:if test="exists($new_tag[not(. = $old_tags)])">
			<xsl:message>Adding tag {$new_tag}</xsl:message>
			<xsl:result-document href="#ChosenElems">
				<xsl:call-template name="add_elem_tag">
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
	
	<!-- Hide/show moods -->
	<xsl:template match="*[ejs:contains-class(., 'mood-title')]/html:a" mode="ixsl:onclick">
		<xsl:sequence select="
				ejs:toggle-class(., ('hide-moods', 'show-moods')),
				ejs:toggle-class(../following-sibling::html:div[1], 'is-hidden')
			"/>
	</xsl:template>
	
	<!-- Pin/unpin Button-->
	<xsl:template match="html:a[ejs:contains-class(.,'pin')]" mode="ixsl:onclick">
		<xsl:variable name="pinned" select="ejs:contains-class(../.., 'is-pinned')" as="xs:boolean"/>
		<xsl:variable name="this.element" select="local:get-id-number(../@id)" as="xs:string"/>
		<xsl:sequence select="ejs:toggle-class(../.., 'is-pinned')"/>
		<xsl:choose>
			<xsl:when test="$pinned">
				<xsl:apply-templates select="id($this.element||'-tag')/html:div/html:a" mode="ixsl:onclick"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:call-template name="add_elem_tag">
					<xsl:with-param name="new_tag" select="$this.element"/>
				</xsl:call-template>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
		
	<!-- Play/Pause Button-->
	<xsl:template match="html:a[@class='play-button']" mode="ixsl:onclick">
		<xsl:variable name="element" select="local:get-id-number(substring-before(@id, '-play-button'))" as="xs:string"/>
		<xsl:variable name="column" select="ancestor::html:div[ejs:contains-class(., 'column')]" as="element()"/>
		<xsl:variable name="playing" as="xs:boolean" select="ejs:contains-class($column, 'is-playing')"/>
		<xsl:variable name="play-or-stop" as="xs:string" select="if ($playing) then 'stop' else 'play'"/>
		<xsl:message>{$play-or-stop} Element {$element}</xsl:message>
		<ixsl:schedule-action http-request="map{
				'method' : 'get',
				'href'   : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/elements/'||$element||'/'||$play-or-stop||'/?auth_token='||$auth_token
			}">
			<xsl:call-template name="ejs:handle-response">
				<xsl:with-param name="action" select="xs:QName('local:play-element')"/>
				<xsl:with-param name="element" tunnel="yes" select="$column"/>
			</xsl:call-template>
		</ixsl:schedule-action>
	</xsl:template>
	
	<!-- Master Stop Response Handling -->
	
	<xsl:template match=".[. eq xs:QName('local:master_stop')]" mode="ejs:action">
		<xsl:call-template name="refresh_state"/>
	</xsl:template>
	
	<!-- Mood Play Response Handling -->
	
	<xsl:template match=".[. eq xs:QName('local:play-mood')]" mode="ejs:action">
		<xsl:call-template name="refresh_state"/>
	</xsl:template>
	
	<!-- Element One-shot Response Handling -->
	<xsl:template match=".[. eq xs:QName('local:play-oneshot')]" mode="ejs:action">
		<xsl:call-template name="refresh_state"/>
	</xsl:template>
	
	<!-- Element Play Response Handling -->
	
	<xsl:template match=".[. eq xs:QName('local:play-element')]" mode="ejs:action">
		<xsl:param name="response" tunnel="yes"/>
		<xsl:apply-templates select="$response" mode="local:play-element"/>
	</xsl:template>
	<xsl:mode name="local:play-element"/>
	<xsl:template mode="local:play-element" match=".[.?status eq 'playing']">
		<xsl:param name="element" tunnel="yes"/>
		<xsl:sequence select="ejs:add-class($element, 'is-playing')"/>
	</xsl:template>
	<xsl:template mode="local:play-element" match=".[.?status eq 'stopped']">
		<xsl:param name="element" tunnel="yes"/>
		<xsl:sequence select="ejs:remove-class($element, 'is-playing')"/>
	</xsl:template>
	
	<!-- 
		Functions
	-->
	
	<!-- Gets type from id prefixes -->
	<xsl:function name="local:get-type-from-id" as="xs:string">
		<xsl:param name="id" as="xs:string"/>
		<xsl:variable name="prefix" select="substring-before($id, ':')"/>
		<xsl:choose>
			<xsl:when test="$prefix = 's'">
				<xsl:text>soundset</xsl:text>
			</xsl:when>
			<xsl:when test="$prefix = 'm'">
				<xsl:text>moods</xsl:text>
			</xsl:when>
			<xsl:when test="$prefix = 'e'">
				<xsl:text>elements</xsl:text>
			</xsl:when>
			<xsl:otherwise>
				<xsl:sequence select="error((), 'Unrecognised ID format while getting ID type: '||$id)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Gets number from prefexed ids -->
	<xsl:function name="local:get-id-number" as="xs:string">
		<xsl:param name="id" as="xs:string"/>
		<xsl:sequence select="if (contains($id, ':')) then substring-after($id, ':') else error((), 'Unrecognised ID format while getting ID number: '||$id)"/>
	</xsl:function>
	
	<!-- set volume controls -->
	<xsl:function name="local:set-volume">
		<xsl:param name="id" as="xs:string"/>
		<xsl:param name="volume" as="xs:double"/>
		<xsl:sequence select="local:set-volume($id, $volume, 1)"/>
	</xsl:function>
	<xsl:function name="local:set-volume">
		<xsl:param name="id" as="xs:string"/>
		<xsl:param name="volume" as="xs:double"/>
		<xsl:param name="max" as="xs:double"/>
		<xsl:variable name="vol_adj" select="xs:integer((if (abs($volume) le $max) then abs($volume) else $max) * 100)" as="xs:integer"/>
		<xsl:variable name="input" select="$id||'-volume-number'"/>
		<xsl:variable name="slider" select="$id||'-volume-slider'"/>
		<xsl:message>Setting volume of {$id} to {$vol_adj}</xsl:message>
		<xsl:for-each select="($input, $slider)">
			<ixsl:set-attribute name="value" object="id(., ixsl:page())" select="$vol_adj"/>
		</xsl:for-each>
	</xsl:function>
	
</xsl:stylesheet>