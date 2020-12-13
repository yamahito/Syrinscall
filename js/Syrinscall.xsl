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
		<xsl:for-each select="$sets">
			<xsl:result-document href="#ChosenSets">
				<xsl:call-template name="add_set">
					<xsl:with-param name="new_tag" select="."/>
				</xsl:call-template>
			</xsl:result-document>
		</xsl:for-each>
		<xsl:for-each select="$elems">
			<ixsl:schedule-action http-request="map{'method': 'get', 'href' : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/elements/'||.||'/?auth_token='||$auth_token}">
				<xsl:call-template name="local:addElement">
					<xsl:with-param name="pinned" select="true()" tunnel="yes"/>
				</xsl:call-template>
			</ixsl:schedule-action>
			<xsl:result-document href="#ChosenElems">
				<xsl:call-template name="add_elem">
					<xsl:with-param name="new_tag" select="."/>
				</xsl:call-template>
			</xsl:result-document>
		</xsl:for-each>
		<xsl:call-template name="populateMoods"/>
		<ixsl:schedule-action wait="2000">
			<xsl:call-template name="refresh_state"/>
		</ixsl:schedule-action>
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
		<xsl:param name="pinned" as="xs:boolean" select="false()" tunnel="yes"/>
		<xsl:message>Adding Music element: {.?name}</xsl:message>
		<xsl:result-document href="#Music">
			<div data-rid="e:{.?pk}" class="{string-join(('column', 'is-hidden'[not($pinned)], 'is-pinned'[$pinned]), ' ')}">
				<div class="music-element element card" id="e:{.?pk}">
					<div class="card-content">
						<div class="media">
							<div class="media-left">
								<span class="icon is-medium">
									<i class="fas fa-lg fa-music"/>
								</span>
							</div>
							<div class="media-content">
								<p class="title is-6">{.?name}</p>
								<p class="subtitle is-6">e:{.?pk}</p>
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
	</xsl:template>
	<xsl:template match=".[.?element_type eq 'oneshot']" mode="local:element">
		<xsl:message>Adding Oneshot element: {.?name}</xsl:message>
		<xsl:result-document href="#OneShots">
			<button type="submit" id="e:{.?pk}" class="play play_element" formaction="https://www.syrinscape.com/online/frontend-api/elements/{.?pk}/play/?format=json">{.?name}</button>
		</xsl:result-document>
	</xsl:template>
	<xsl:template match=".[.?element_type eq 'sfx']" mode="local:element">
		<xsl:param name="pinned" as="xs:boolean" select="false()" tunnel="yes"/>
		<xsl:message>Adding SFX element: {.?name}</xsl:message>
		<xsl:result-document href="#Elements">
			<div data-rid="e:{.?pk}" class="{string-join(('column', 'is-hidden'[not($pinned)], 'is-pinned'[$pinned]), ' ')}">
				<div class="sfx-element element card" id="e:{.?pk}">
					<div class="card-content">
						<div class="media">
							<div class="media-left">
								<span class="icon is-medium">
									<i class="fas fa-lg fa-volume-up"/>
								</span>
							</div>
							<div class="media-content">
								<p class="title is-6">{.?name}</p>
								<p class="subtitle is-6">e:{.?pk}</p>
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
	</xsl:template>
	
	<xsl:template name="card-footer">
		<footer class="card-footer">
			<div id="e:{.?pk}-play" class="card-control play">
				<a id="e:{.?pk}-play-button" class="play-button">
					<i class="play-pause"/>
				</a>
			</div>
			<div id="e:{.?pk}-volume" class="card-control volume">
				<div class="volume-number">
					<input id="e:{.?pk}-volume-number" autocomplete="off" data-rid="e:{.?pk}" class="input" type="number" min="0" max="100" step="1" value="{xs:integer(100 * .?initial_volume)}"/>
				</div>
				<div class="volume-slider">
					<input id="e:{.?pk}-volume-slider" autocomplete="off" data-rid="e:{.?pk}" class="slider" type="range" min="0" max="100" step="1" value="{xs:integer(100 * .?initial_volume)}"/>
				</div>
			</div>
		</footer>
	</xsl:template>
	
	<xsl:template name="local:addMoods">
		<xsl:context-item as="map(*)" use="required"/>
		<xsl:param name="soundset" as="xs:string"/>
		<xsl:variable name="moods" select="parse-json(.?body)" as="array(*)?"/>
		<xsl:variable name="mood_number" select="array:size($moods)" as="xs:integer"/>
		<xsl:message>Found {$mood_number} moods...</xsl:message>
		<xsl:iterate select="(1 to $mood_number)[$mood_number ge 1]">
			<xsl:param name="elements" select="for $e in $elems return 'https://www.syrinscape.com/online/frontend-api/elements/'||$e||'/'" as="xs:string*"/>
			<xsl:on-completion>
				<xsl:for-each select="$elements">
					<xsl:message>fetching element at {.}</xsl:message>
					<ixsl:schedule-action http-request="map{'method': 'get', 'href' : $CORSproxy||.||'?auth_token='||$auth_token}">
						<xsl:call-template name="local:addElement"/>
					</ixsl:schedule-action>
				</xsl:for-each>
			</xsl:on-completion>
			<xsl:variable name="this.mood" select="$moods(.)"/>
			<xsl:variable name="id" select="$this.mood?pk"/>
			<xsl:variable name="name" select="$this.mood?name"/>
			<xsl:message>Adding mood: {$name}</xsl:message>
			<xsl:variable name="elems" as="map(*)*">
				<xsl:for-each select="(1 to array:size($moods(.)?elements))">
					<xsl:variable name="this.element" select="$this.mood?elements(.)"/>
					<xsl:variable name="url" select="$this.element?element"/>
					<xsl:map>
						<xsl:map-entry key="'id'" select="replace($url, 'https://www.syrinscape.com/online/frontend-api/elements/(\d+)/', 'e:$1')"/>
						<xsl:map-entry key="'url'" select="$url"/>
						<xsl:map-entry key="'plays'" select="$this.element?plays"/> 
					</xsl:map>
				</xsl:for-each>
			</xsl:variable>
			<xsl:result-document href="#{$soundset}">
				<button type="submit" id="m:{$id}" data-elements="{string-join($elems[.?plays]?id, ' ')}" class="play play_mood" formaction="https://www.syrinscape.com/online/frontend-api/moods/{$id}/play/?format=json">{$name}</button>
			</xsl:result-document>
			<xsl:next-iteration>
				<xsl:with-param name="elements" select="distinct-values(($elements, $elems?url))"/>
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
	
	<!-- Add Element Tag -->
	<xsl:template name="add_elem">
		<xsl:param name="new_tag" as="xs:string"/>
		<xsl:variable name="old_tags" as="xs:string?" select="id('elemsParams', ixsl:page())/@value"/>
		<div class="control">
			<div class="tags has-addons">
				<a class="tag is-primary">{$new_tag}</a>
				<a class="tag is-delete"/>
			</div>
		</div>
		<ixsl:set-attribute name="value" select="string-join(distinct-values((tokenize($old_tags, '\+'), $new_tag)), '+')" object="id('elemsParams', ixsl:page())"/>
	</xsl:template>
	
	<!-- Refresh state -->
	<xsl:template name="refresh_state">
		<ixsl:schedule-action http-request="map{
				'method' : 'get',
				'href'   : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/state/?auth_token='||$auth_token
			}">
			<xsl:call-template name="handle_state"/>
		</ixsl:schedule-action>
	</xsl:template>
	
	<xsl:template name="clear_state">
		<xsl:message>Clearing state...</xsl:message>
		<xsl:sequence select="ejs:remove-class((id('Moods', ixsl:page())/html:div/html:button, id('MoodElements', ixsl:page())/html:div/html:div), 'is-playing')"/>
		<xsl:sequence select="ejs:add-class(id('MoodElements', ixsl:page())/html:div/html:div[not(ejs:contains-class(., 'is-pinned'))], 'is-hidden')"/>
	</xsl:template>
	
	<xsl:template name="handle_state">
		<xsl:context-item as="map(*)" use="required"/>
		<xsl:message>Acquiring Current State</xsl:message>
		<xsl:variable name="state" select="parse-json(.?body)"/>
		<xsl:variable name="current-mood" as="xs:string?" select="string($state?mixpanel-current-mood?pk)"/>
		<xsl:call-template name="clear_state"/>
		<xsl:sequence select="
			local:set-volume('master', $state?global?volume, 1.5),
			local:set-volume('oneshot', $state?global?oneshot_volume)
			"/>
		<xsl:apply-templates mode="local:status" select="id('m:'||$current-mood, ixsl:page())">
			<xsl:with-param name="state" select="$state" tunnel="yes"/>
		</xsl:apply-templates>
	</xsl:template>
	
	<!-- status mode -->
	<xsl:mode name="local:status" on-multiple-match="use-last"/>
	
	<xsl:template match="html:button[ejs:contains-class(., 'play_mood')]" mode="local:status">
		<xsl:param name="state" as="map(*)" tunnel="yes"/>
		<xsl:variable name="pk" select="local:get-id-number(@id)"/>
		<xsl:variable name="elements" select="tokenize(@data-elements, '\s')" as="xs:string*"/>
		<!-- Update mood -->
		<xsl:if test="$state?mood($pk)?is_playing">
			<xsl:sequence select="ejs:add-class(., 'is-playing')"/>
			<xsl:message>Mood {@id} playing</xsl:message>
			<xsl:apply-templates mode="#current" select="$elements!id(., ixsl:page())"/>
		</xsl:if>
		<xsl:on-empty>
			<xsl:message>Mood {@id} not playing</xsl:message>
		</xsl:on-empty>
	</xsl:template>
	
	<xsl:template match="html:div[@id=('Music', 'Elements')]/html:div/html:div" mode="local:status">
		<xsl:param name="state" as="map(*)" tunnel="yes"/>
		<xsl:variable name="pk" select="local:get-id-number(@id)"/>
		<xsl:message>Showing element {@id}</xsl:message>
		<xsl:sequence select="
			local:set-volume(@id, ($state('element')($pk)?vol, id(@id||'-volume-number')/@value div 100, 0)[1]),
			ejs:remove-class(.., 'is-hidden'),
			ejs:add-class(.., 'is-playing')
		"/>
	</xsl:template>
	
	<!--
		ixsl:onchange Mode
	-->
	<xsl:mode name="ixsl:onchange" on-multiple-match="use-last"/>
	
	<!-- adjust volume -->
	<xsl:template match="html:input[@data-rid][ends-with(@id, '-volume-number') or ends-with(@id, '-volume-slider')]" mode="ixsl:onchange">
		<xsl:variable name="vol" select="(ixsl:get(ixsl:event(), 'target.value') div 100, @value div 100, 0)[1]" as="xs:double"/>
		<xsl:sequence select="local:set-volume(@data-rid, $vol, @max div 100)"/>
		<xsl:choose>
			<xsl:when test="@data-rid eq 'master'">
				<ixsl:schedule-action http-request="map{
						'method': 'patch',
						'href'  : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/state/global/?auth_token='||$auth_token,
						'body'  : serialize(map{'volume': $vol}, map{'method':'json'}),
						'media-type'	:	'application/json'
					}">
					<xsl:call-template name="refresh_state"/>
				</ixsl:schedule-action>
			</xsl:when>
			<xsl:when test="@data-rid eq 'oneshot'">
				<ixsl:schedule-action http-request="map{
						'method': 'patch',
						'href'  : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/state/global/?auth_token='||$auth_token,
						'body'  : serialize(map{'oneshot_volume': $vol}, map{'method':'json'}),
						'media-type'	:	'application/json'
					}">
					<xsl:call-template name="refresh_state"/>
				</ixsl:schedule-action>
			</xsl:when>
			<xsl:otherwise>
				<ixsl:schedule-action http-request="map{
						'method': 'post',
						'href'  : $CORSproxy||'https://www.syrinscape.com/online/frontend-api/elements/'||local:get-id-number(@data-rid)||'/set_current_volume/?auth_token='||$auth_token,
						'body'  : serialize(map{'current_volume': $vol}, map{'method':'json'}),
						'media-type'	:	'application/json'
					}">
					<xsl:call-template name="refresh_state"/>
				</ixsl:schedule-action>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	
	<xsl:template name="handle_http">
		<xsl:context-item as="map(*)" use="required"/>
		<xsl:message select="serialize(., map{'method':'json'})"/>
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
	<xsl:template match="html:button[tokenize(@class, '\s') = 'play']" mode="ixsl:onclick">
		<xsl:message>Playing {.} (ID:{@id})</xsl:message>
		<xsl:call-template name="refresh_state"/>
	</xsl:template>
	
	<!-- Master Stop All sounds Button-->
	<xsl:template match="html:button[@id = 'master_stop']" mode="ixsl:onclick">
		<xsl:message>Stopping all sounds.</xsl:message>
		<xsl:call-template name="refresh_state"/>
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
	
	<!-- Add Element Tags Button-->
	<xsl:template match="html:button[@id='choose_elem']" mode="ixsl:onclick">
		<xsl:variable name="new_tag" select="normalize-space(id('add_elem'))[. ne '']" as="xs:string?"/>
		<xsl:variable name="old_tags" select="(id('ChosenElems')/html:div/html:div/html:a ! normalize-space(.))[.ne '']" as="xs:string*"/>
		<xsl:if test="exists($new_tag[not(. = $old_tags)])">
			<xsl:message>Adding tag {$new_tag}</xsl:message>
			<xsl:result-document href="#ChosenElems">
				<xsl:call-template name="add_elem">
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
	
	<!-- Pin/unpin Button-->
	<xsl:template match="html:a[@class='pin']" mode="ixsl:onclick">
		<xsl:variable name="pinned" select="ejs:contains-class(../.., 'is-pinned')" as="xs:boolean"/>
		<xsl:variable name="this.element" select="local:get-id-number(../@id)" as="xs:string"/>
		<xsl:variable name="otherValues" select="tokenize(id('elemsParams', ixsl:page()), '\+')/@value[not(. eq $this.element)]" as="xs:string*"/>
		<xsl:sequence select="ejs:toggle-class(../.., 'is-pinned')"/>
		<ixsl:set-attribute name="value" select="string-join(distinct-values(($otherValues, 'is-pinned'[not($pinned)])), '+')" object="id('elemsParams', ixsl:page())"/>
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
				<xsl:sequence select="error((), 'Unrecognised ID format: '||$id)"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:function>
	<!-- Gets number from prefexed ids -->
	<xsl:function name="local:get-id-number" as="xs:string">
		<xsl:param name="id" as="xs:string"/>
		<xsl:sequence select="if (contains($id, ':')) then substring-after($id, ':') else error((), 'Unrecognised ID format: '||$id)"/>
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