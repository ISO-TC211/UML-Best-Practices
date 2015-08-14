<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
    <!-- (c) 2001-2013 interactive instruments GmbH, Bonn -->
    
    <xsl:output indent="yes" method="xml"/>
    
    <xsl:template match="messages">
        <messages>
            <!-- Copy message elements to the output document, sorted based upon their @id values -->
            <xsl:for-each select="message">
                <xsl:sort select="@id" lang="en"/>
                <xsl:copy-of select="."/>
            </xsl:for-each>            
        </messages>        
    </xsl:template>
    
</xsl:stylesheet>