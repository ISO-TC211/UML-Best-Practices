<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns="http://schemas.openxmlformats.org/package/2006/relationships"
  exclude-result-prefixes="xs"
  version="2.0">
  
  <xsl:output method="xml" encoding="UTF-8" indent="yes"/> 
  
  <!-- The path to the image info xml is set automatically by ShapeChange. -->
  <xsl:param name="imageInfoXmlPath"/>
  
  <!-- When executed with ShapeChange, the absolute URI to the image info XML is automatically determined via a custom URI resolver. -->
  <xsl:variable name="imageInfo" select="document($imageInfoXmlPath)"/>
    
  <!-- Default: copy everything -->
  <xsl:template match="node()|@*" name="identity">
    <xsl:copy>
      <xsl:apply-templates select="@*|node()"/>
    </xsl:copy>
  </xsl:template>
  
  <xsl:template match="*[local-name(.) = 'Relationship'][last()]">
    <xsl:call-template name="identity"/>
    <xsl:apply-templates select="$imageInfo/images/image"/>
  </xsl:template>
  
  <xsl:template match="image">
    <xsl:variable name="img" select="."/>
    <Relationship>
      <xsl:attribute name="Id">
        <xsl:value-of disable-output-escaping="no" select="$img/@id"/>
      </xsl:attribute>
      <xsl:attribute name="Target">
        <xsl:text>media/</xsl:text>
        <xsl:value-of disable-output-escaping="no" select="$img/@relPath"/>
      </xsl:attribute>
      <xsl:attribute name="Type">
        <xsl:text>http://schemas.openxmlformats.org/officeDocument/2006/relationships/image</xsl:text>
      </xsl:attribute>
    </Relationship>
  </xsl:template>
  
</xsl:stylesheet>