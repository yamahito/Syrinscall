<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:math="http://www.w3.org/2005/xpath-functions/math"
	xmlns:ixsl="http://saxonica.com/ns/interactiveXSLT"
	xmlns:js="http://saxonica.com/ns/globalJS"
	xmlns:local="http://ns.expertml.com/saxonjs"
	xmlns:saxon="http://saxon.sf.net/"
	xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
	extension-element-prefixes="ixsl"
	exclude-result-prefixes="#all"
	version="3.0">
	
	<xd:doc scope="stylesheet">
		<xd:desc>
			<xd:p><xd:b>Created on:</xd:b> Nov 25, 2020</xd:p>
			<xd:p><xd:b>Author:</xd:b> TFJH</xd:p>
			<xd:p>This stylesheet contains various useful SaxonJS functions</xd:p>
		</xd:desc>
	</xd:doc>
	
	<xd:doc>
		<xd:desc>This function is a convenience function to see if the class of (every) given element contains a class value.</xd:desc>
		<xd:param name="element">The element(s) with @class to check</xd:param>
		<xd:param name="class">The class token to check against</xd:param>
	</xd:doc>
	<xsl:function name="local:contains-class" as="xs:boolean">
		<xsl:param name="element" as="element()*"/>
		<xsl:param name="class" as="xs:string"/>
		<xsl:if test="matches($class, '\s')">
			<xsl:sequence select="error((), 'class parameter must be a single token')"/>
		</xsl:if>
		<xsl:sequence select="every $e in $element/@class satisfies ($e!tokenize(., '\s') = $class)"/>
	</xsl:function>
	
	<xd:doc>
		<xd:desc>This function adds one or more classes to an element's @class value</xd:desc>
		<xd:param name="element">The element(s) for which to change class value</xd:param>
		<xd:param name="class">The class or classes to add.  Classes may be a sequence of strings, each of which may consist of a space separated list of tokens.</xd:param>
	</xd:doc>
	<xsl:function name="local:add-class" as="element(ixsl:set-attribute)*">
		<xsl:param name="element" as="element()*"/>
		<xsl:param name="class" as="xs:string*"/>
		<xsl:variable name="addedClasses" select="distinct-values($class!tokenize(., '\s'))"/>
		<!--<xsl:message>Adding classes to elements: {$element ! local-name(.)}</xsl:message>-->
		<xsl:for-each select="$element">
			<xsl:variable name="classes" as="xs:string*" select="tokenize(@class, '\s')"/>
			<!--<xsl:message>Adding class(es) "{$addedClasses}" to {local-name(.)} element {generate-id(.)} with existing class(es): {@class}"</xsl:message>-->
			<ixsl:set-attribute name="class" select="string-join(distinct-values(($classes, $addedClasses)), ' ')" object="."/>
		</xsl:for-each>
	</xsl:function>
	
	<xd:doc>
		<xd:desc>This function removes one or more classes in an element's @class value</xd:desc>
		<xd:param name="element">The element(s) for which to change class value</xd:param>
		<xd:param name="class">The class or classes to remove.  Classes may be a sequence of strings, each of which may consist of a space separated list of tokens.</xd:param>
	</xd:doc>
	<xsl:function name="local:remove-class" as="element(ixsl:set-attribute)*">
		<xsl:param name="element" as="element()*"/>
		<xsl:param name="class" as="xs:string*"/>
		<xsl:variable name="removedClasses" select="distinct-values($class!tokenize(., '\s'))"/>
		<xsl:for-each select="$element">
			<xsl:variable name="classes" as="xs:string*" select="tokenize(@class, '\s')"/>
			<xsl:variable name="classResult" as="xs:string*" select="$class[not(. = $removedClasses)]"/>
			<!--<xsl:message>Removing class(es) "{$removedClasses}" from {local-name(.)} element {generate-id(.)} with existing class(es): {@class}"</xsl:message>-->
			<xsl:choose>
				<xsl:when test="exists($classResult)">
					<ixsl:set-attribute name="class" select="string-join($classResult, ' ')" object="."/>
				</xsl:when>
				<xsl:otherwise>
					<ixsl:remove-attribute name="class" object="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>	
	</xsl:function>
	
	<xd:doc>
		<xd:desc>This function removes classes from an element's @class value if they is present, and adds them if not.</xd:desc>
		<xd:param name="element">The element(s) for which to change class value</xd:param>
		<xd:param name="class">The class or classes to toggle.  Classes may be a sequence of strings, each of which may consist of a space separated list of tokens.</xd:param>
	</xd:doc>
	<xsl:function name="local:toggle-class" as="element(ixsl:set-attribute)*">
		<xsl:param name="element" as="element()*"/>
		<xsl:param name="class" as="xs:string*"/>
		<xsl:variable name="toggleClasses" as="xs:string*" select="distinct-values($class!tokenize(., '\s'))"/>
		<xsl:for-each select="$element">
			<xsl:variable name="classes" as="xs:string*" select="tokenize(@class, '\s')"/>
			<xsl:variable name="removedClasses" select="$classes[. = $toggleClasses]" as="xs:string*"/>
			<xsl:variable name="addedClasses" select="$toggleClasses[not(. = $classes)]" as="xs:string*"/>
			<xsl:variable name="classResult" as="xs:string*" select="$classes[not(. = $removedClasses)], $addedClasses"/>
			<!--<xsl:message>Toggling class(es) "{$toggleClasses}" of {local-name(.)} element {generate-id(.)} with existing class(es): {@class}"</xsl:message>-->
			<xsl:choose>
				<xsl:when test="exists($classResult)">
					<ixsl:set-attribute name="class" select="string-join($classResult, ' ')" object="."/>
				</xsl:when>
				<xsl:otherwise>
					<ixsl:remove-attribute name="class" object="."/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:for-each>
	</xsl:function>
	
	<xd:doc>
		<xd:desc>This template simply returns a message (for use with ixsl:schedule-action)</xd:desc>
		<xd:param name="value">The value to be returned in the message</xd:param>
	</xd:doc>
	<xsl:template name="local:message">
		<xsl:param name="value" as="xs:string"/>
		<xsl:message>{$value}</xsl:message>
	</xsl:template>
	
</xsl:stylesheet>