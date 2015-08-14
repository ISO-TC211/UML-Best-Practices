<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform" exclude-result-prefixes="xsl">
    <!-- (c) 2001-2013 interactive instruments GmbH, Bonn -->

    <!-- ==================== -->
    <!-- Imports and Includes -->
    <!-- ==================== -->
    
    <!-- include the stylesheet with localization variables -->
    <xsl:include href="localization.xsl"/>
    
    <!-- =============== -->
    <!-- Output settings -->
    <!-- =============== -->
    <xsl:output indent="yes" method="xml"/>

    <!-- ================= -->
    <!-- Catalogue content -->
    <!-- ================= -->
    <!-- The path to the catalogue tmp xml is set automatically by ShapeChange. -->
    <xsl:param name="catalogXmlPath"/>
    <!-- When executed with ShapeChange, the absolute URI to the catalog XML is automatically determined via a custom URI resolver. -->
    <xsl:variable name="catalog" select="document($catalogXmlPath)"/>
    <xsl:key match="/*/*[@id]" name="modelElement" use="@id"/>

    <!-- ============== -->
    <!-- Docx style XML -->
    <!-- ============== -->    
    <!-- The path to the docx internal document.xml is set automatically by ShapeChange. -->
    <xsl:param name="styleXmlPath"/>
    <!-- When executed with ShapeChange, the absolute URI to the style XML is automatically determined via a custom URI resolver. -->
    <xsl:variable name="heading1Id"
        select="document($styleXmlPath)/w:styles/w:style[w:name/@w:val = 'heading 1']/@w:styleId"/>
    <xsl:variable name="heading2Id"
        select="document($styleXmlPath)/w:styles/w:style[w:name/@w:val = 'heading 2']/@w:styleId"/>
    <xsl:variable name="heading3Id"
        select="document($styleXmlPath)/w:styles/w:style[w:name/@w:val = 'heading 3']/@w:styleId"/>

    <!-- ============================================ -->
    <!-- Docx transformation parameters and variables -->
    <!-- ============================================ -->
    <xsl:param name="DOCX_PLACEHOLDER">ShapeChangeFeatureCatalogue</xsl:param>
    <xsl:variable name="fcRefId">_RefFeatureCatalogue</xsl:variable>

    <!-- Indentation amount is measured in twentieths of a point (dxa): 1mm = 56.6929 dxa -->
    <!-- 
        1,25 cm ~ 708 dxa 
        1,00 cm ~ 567 dxa
        0,75 cm ~ 425 dxa
    -->
    <!-- Define amount of indentation for non-table lines (e.g. application schema version, scope) in dxa -->
    <xsl:variable name="indent">708</xsl:variable>
    <!-- Define amount of indentation for table lines of table entries (e.g. attribute details) in dxa -->
    <xsl:variable name="entryLineIndent">425</xsl:variable>
    <!-- Define amount of indentation for the table of class entries (e.g. enumeration values) in dxa -->
    <xsl:variable name="clentryTableIndent">0</xsl:variable>

    <!-- Define the width (in 1/50 percent, for example 30%=1500) for each of the columns in a feature type table. -->
    <xsl:variable name="ftypeTableColumnOneWidth">1500</xsl:variable>
    <xsl:variable name="ftypeTableColumnTwoWidth">3500</xsl:variable>

    <!-- Define the width (in 1/50 percent, for example 30%=1500) for each of the columns in a class entry table (e.g. for enumeration values). -->
    <xsl:variable name="clentryTableColumnOneWidth">1500</xsl:variable>
    <xsl:variable name="clentryTableColumnTwoWidth">3500</xsl:variable>

    <!-- Define the width (in 1/50 percent, for example 30%=1500) for each of the columns in a class entry table (e.g. for enumeration values). -->
    <xsl:variable name="entryTableColumnNameWidth">900</xsl:variable>
    <xsl:variable name="entryTableColumnDefWidth">1900</xsl:variable>
    <xsl:variable name="entryTableColumnMultWidth">400</xsl:variable>
    <xsl:variable name="entryTableColumnTypeWidth">900</xsl:variable>
    <xsl:variable name="entryTableColumnRemarkWidth">900</xsl:variable>

    <!-- ======================== -->
    <!-- Transformation templates -->
    <!-- ======================== -->
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
    </xsl:template>

    <xsl:template
	    match="/w:document/w:body/w:p[w:r/w:t[contains(text(),$DOCX_PLACEHOLDER)]] | /w:document/w:body/w:p[w:ins/w:r/w:t[contains(text(),$DOCX_PLACEHOLDER)]]">
        <xsl:apply-templates select="$catalog/FeatureCatalogue"/>
    </xsl:template>

    <xsl:template match="FeatureCatalogue">
        <w:p>
			<w:pPr>
                <w:pStyle w:val="Standard"/>
				<w:sectPr>
					<w:pgSz w:w="11906" w:h="16838" w:orient="portrait"/>
				</w:sectPr>
            </w:pPr>
        </w:p>
        <w:p>
			<w:pPr>
                <w:pStyle>
                    <xsl:attribute name="w:val">
                        <xsl:value-of disable-output-escaping="no" select="$heading1Id"/>
                    </xsl:attribute>
                </w:pStyle>
            </w:pPr>
            <w:bookmarkStart w:id="0">
                <xsl:attribute name="w:name">
                    <xsl:value-of disable-output-escaping="no" select="$fcRefId"/>
                </xsl:attribute>
            </w:bookmarkStart>
            <w:r>
                <w:t>
                    <xsl:value-of select="$fc.FeatureCatalogue"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of disable-output-escaping="no" select="name"/>
                </w:t>
            </w:r>
            <w:bookmarkEnd w:id="0"/>
        </w:p>
        <!--w:p/-->
        <w:p>
            <w:r>
                <w:rPr>
                    <w:b/>
                </w:rPr>
                <w:t>
                    <xsl:value-of select="$fc.Version"/>
                    <xsl:text>:</xsl:text>
                </w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:pPr>
                <w:ind w:left="{$indent}"/>
            </w:pPr>
            <w:r>
                <w:t>
                    <xsl:value-of disable-output-escaping="no" select="versionNumber"/>
                </w:t>
            </w:r>
        </w:p>
        <!--w:p/-->
        <w:p>
            <w:r>
                <w:rPr>
                    <w:b/>
                </w:rPr>
                <w:t>
                    <xsl:value-of select="$fc.Date"/>
                    <xsl:text>:</xsl:text>
                </w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:pPr>
                <w:ind w:left="{$indent}"/>
            </w:pPr>
            <w:r>
                <w:t>
                    <xsl:value-of disable-output-escaping="no" select="versionDate"/>
                </w:t>
            </w:r>
        </w:p>
        <!--w:p/-->
        <w:p>
            <w:r>
                <w:rPr>
                    <w:b/>
                </w:rPr>
                <w:t>
                    <xsl:value-of select="$fc.Scope"/>
                    <xsl:text>:</xsl:text>
                </w:t>
            </w:r>
        </w:p>
        <xsl:for-each select="scope">
            <w:p>
                <w:pPr>
                    <w:ind w:left="{$indent}"/>
                </w:pPr>
                <w:r>
                    <w:t>
                        <xsl:value-of disable-output-escaping="no" select="."/>
                    </w:t>
                </w:r>
            </w:p>
        </xsl:for-each>
        <!--w:p/-->
        <w:p>
            <w:r>
                <w:rPr>
                    <w:b/>
                </w:rPr>
                <w:t>
                    <xsl:value-of select="$fc.ResponsibleOrganization"/>
                    <xsl:text>:</xsl:text>
                </w:t>
            </w:r>
        </w:p>
        <w:p>
            <w:pPr>
                <w:ind w:left="{$indent}"/>
            </w:pPr>
            <w:r>
                <w:t>
                    <xsl:value-of disable-output-escaping="no" select="producer"/>
                </w:t>
            </w:r>
        </w:p>
        <!--w:p/-->
        <xsl:for-each select="Package|ApplicationSchema">
            <xsl:sort select="./code"/>
            <xsl:sort select="./name"/>
            <xsl:apply-templates mode="detail" select="."/>
        </xsl:for-each>
        <w:p>
			<w:pPr>
                <w:pStyle w:val="Standard"/>
				<w:sectPr>
					<w:type w:val="nextPage"/>
					<w:pgSz w:h="11906" w:w="16838" w:orient="landscape"/>
				</w:sectPr>
            </w:pPr>
        </w:p>
        <!--w:p/-->
    </xsl:template>

    <xsl:template match="Package|ApplicationSchema" mode="detail">
        <xsl:variable name="package" select="."/>
        <!-- Test if there are any (feature) types or packages that belong to this package. -->
        <xsl:if
            test="/FeatureCatalogue/FeatureType/package[attribute::idref=$package/@id]|/FeatureCatalogue/Package/parent[attribute::idref=$package/@id]">
            <w:p>
                <w:pPr>
                    <w:pStyle>
                        <xsl:attribute name="w:val">
                            <xsl:value-of disable-output-escaping="no" select="$heading2Id"/>
                        </xsl:attribute>
                    </w:pStyle>
                </w:pPr>
                <w:bookmarkStart w:id="0">
                    <xsl:attribute name="w:name">
                        <xsl:text>_Ref</xsl:text>
                        <xsl:value-of disable-output-escaping="no" select="$package/@id"/>
                    </xsl:attribute>
                </w:bookmarkStart>
                <w:r>
                    <w:t>
                        <xsl:choose>
                            <xsl:when test="count($package/parent)=1">
                                <xsl:value-of select="$fc.Package"/>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$fc.ApplicationSchema"/>
                            </xsl:otherwise>
                        </xsl:choose>
                        <xsl:text>: </xsl:text>
                        <xsl:value-of disable-output-escaping="no" select="name"/>
                    </w:t>
                </w:r>
                <w:bookmarkEnd w:id="0"/>
            </w:p>
            <!--w:p/-->
            <xsl:if test="title">
                <w:p>
                    <w:r>
                        <w:rPr>
                            <w:b/>
                        </w:rPr>
                        <w:t>
                            <xsl:value-of select="$fc.Title"/>
                            <xsl:text>:</xsl:text>
                        </w:t>
                    </w:r>
                </w:p>
                <w:p>
                    <w:pPr>
                        <w:ind w:left="{$indent}"/>
                    </w:pPr>
                    <w:r>
                        <w:t>
                            <xsl:value-of disable-output-escaping="no" select="title"/>
                        </w:t>
                    </w:r>
                </w:p>
            </xsl:if>
            <xsl:if test="definition">
                <w:p>
                    <w:r>
                        <w:rPr>
                            <w:b/>
                        </w:rPr>
                        <w:t>
                            <xsl:value-of select="$fc.Definition"/>
                            <xsl:text>:</xsl:text>
                        </w:t>
                    </w:r>
                </w:p>
                <xsl:for-each select="definition">
                    <w:p>
                        <w:pPr>
                            <w:ind w:left="{$indent}"/>
                        </w:pPr>
                        <w:r>
                            <w:t>
                                <xsl:value-of disable-output-escaping="no" select="."/>
                            </w:t>
                        </w:r>
                    </w:p>
                </xsl:for-each>
            </xsl:if>
            <xsl:if test="description">
                <w:p>
                    <w:r>
                        <w:rPr>
                            <w:b/>
                        </w:rPr>
                        <w:t>
                            <xsl:value-of select="$fc.Description"/>
                            <xsl:text>:</xsl:text>
                        </w:t>
                    </w:r>
                </w:p>
                <xsl:for-each select="description">
                    <w:p>
                        <w:pPr>
                            <w:ind w:left="{$indent}"/>
                        </w:pPr>
                        <w:r>
                            <w:t>
                                <xsl:value-of disable-output-escaping="no" select="."/>
                            </w:t>
                        </w:r>
                    </w:p>
                </xsl:for-each>
            </xsl:if>
            <xsl:if test="versionNumber">
                <w:p>
                    <w:r>
                        <w:rPr>
                            <w:b/>
                        </w:rPr>
                        <w:t>
                            <xsl:value-of select="$fc.Version"/>
                            <xsl:text>:</xsl:text>
                        </w:t>
                    </w:r>
                </w:p>
                <w:p>
                    <w:pPr>
                        <w:ind w:left="{$indent}"/>
                    </w:pPr>
                    <w:r>
                        <w:t>
                            <xsl:value-of disable-output-escaping="no" select="versionNumber"/>
                        </w:t>
                    </w:r>
                </w:p>
            </xsl:if>
            <xsl:if test="versionDate">
                <w:p>
                    <w:r>
                        <w:rPr>
                            <w:b/>
                        </w:rPr>
                        <w:t>
                            <xsl:value-of select="$fc.Date"/>
                            <xsl:text>:</xsl:text>
                        </w:t>
                    </w:r>
                </w:p>
                <w:p>
                    <w:pPr>
                        <w:ind w:left="{$indent}"/>
                    </w:pPr>
                    <w:r>
                        <w:t>
                            <xsl:value-of disable-output-escaping="no" select="versionDate"/>
                        </w:t>
                    </w:r>
                </w:p>
            </xsl:if>
            <xsl:if test="producer">
                <w:p>
                    <w:r>
                        <w:rPr>
                            <w:b/>
                        </w:rPr>
                        <w:t>
                            <xsl:value-of select="$fc.ResponsibleOrganization"/>
                            <xsl:text>:</xsl:text>
                        </w:t>
                    </w:r>
                </w:p>
                <w:p>
                    <w:pPr>
                        <w:ind w:left="{$indent}"/>
                    </w:pPr>
                    <w:r>
                        <w:t>
                            <xsl:value-of disable-output-escaping="no" select="producer"/>
                        </w:t>
                    </w:r>
                </w:p>
            </xsl:if>
            <xsl:if test="/FeatureCatalogue/Package[parent/@idref=$package/@id]">
                <w:p>
                    <w:r>
                        <w:rPr>
                            <w:b/>
                        </w:rPr>
                        <w:t>
                            <xsl:value-of select="$fc.SubPackage"/>
                            <xsl:text>:</xsl:text>
                        </w:t>
                    </w:r>
                </w:p>
                <xsl:for-each select="/FeatureCatalogue/Package[parent/@idref=$package/@id]">
                    <xsl:sort select="./code"/>
                    <xsl:sort select="./name"/>
                    <w:p>
                        <w:pPr>
                            <w:ind w:left="{$indent}"/>
                        </w:pPr>
                        <w:r>
                            <w:fldChar w:fldCharType="begin"/>
                        </w:r>
                        <w:r>
                            <w:instrText xml:space="preserve"><xsl:text> REF _Ref</xsl:text><xsl:value-of select="@id"/><xsl:text> \h </xsl:text></w:instrText>
                        </w:r>
                        <w:r>
                            <w:fldChar w:fldCharType="separate"/>
                        </w:r>
                        <w:r>
                            <w:t>
                                <xsl:value-of disable-output-escaping="no" select="name"/>
                            </w:t>
                        </w:r>
                        <w:r>
                            <w:fldChar w:fldCharType="end"/>
                        </w:r>
                    </w:p>
                </xsl:for-each>
            </xsl:if>
            <xsl:if test="parent">
                <w:p>
                    <w:r>
                        <w:rPr>
                            <w:b/>
                        </w:rPr>
                        <w:t>
                            <xsl:value-of select="$fc.ParentPackage"/>
                            <xsl:text>:</xsl:text>
                        </w:t>
                    </w:r>
                </w:p>
                <w:p>
                    <w:pPr>
                        <w:ind w:left="{$indent}"/>
                    </w:pPr>
                    <w:r>
                        <w:fldChar w:fldCharType="begin"/>
                    </w:r>
                    <w:r>
                        <w:instrText xml:space="preserve"><xsl:text> REF _Ref</xsl:text><xsl:value-of select="parent/@idref"/><xsl:text> \h </xsl:text></w:instrText>
                    </w:r>
                    <w:r>
                        <w:fldChar w:fldCharType="separate"/>
                    </w:r>
                    <w:r>
                        <w:t>
                            <xsl:value-of disable-output-escaping="no"
                                select="key('modelElement',$package/parent/@idref)/name"/>
                        </w:t>
                    </w:r>
                    <w:r>
                        <w:fldChar w:fldCharType="end"/>
                    </w:r>
                </w:p>
            </xsl:if>
            <xsl:for-each select="/FeatureCatalogue/FeatureType[package/@idref=$package/@id]">
                <xsl:sort select="./code"/>
                <xsl:sort select="./name"/>
                <xsl:apply-templates mode="detail" select="."/>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>

    <xsl:template match="FeatureType" mode="detail">       
        <xsl:variable name="featuretype" select="."/>
        <xsl:variable name="package" select="key('modelElement',$featuretype/package/@idref)"/>
        
        <!--w:p/-->
        <w:p>
            <w:pPr>
                <w:pStyle>
                    <xsl:attribute name="w:val">
                        <xsl:value-of disable-output-escaping="no" select="$heading3Id"/>
                    </xsl:attribute>
                </w:pStyle>
            </w:pPr>
            <w:bookmarkStart w:id="0">
                <xsl:attribute name="w:name">
                    <xsl:text>_Ref</xsl:text>
                    <xsl:value-of disable-output-escaping="no" select="$featuretype/@id"/>
                </xsl:attribute>
            </w:bookmarkStart>
            <w:r>
                <xsl:element name="w:t">
                    <xsl:value-of disable-output-escaping="no" select="$featuretype/name"/>
                    <xsl:if test="$featuretype/type">
                    	<xsl:text> (</xsl:text><xsl:value-of select="$featuretype/type"/><xsl:text>)</xsl:text>
                    </xsl:if>
                </xsl:element>
            </w:r>
            <w:bookmarkEnd w:id="0"/>
        </w:p>
        <w:tbl>
            <w:tblPr>
                <w:tblW w:type="pct" w:w="5000"/>
                <w:tblBorders>
                    <w:top w:color="auto" w:space="0" w:sz="4" w:val="single"/>
                    <w:left w:color="auto" w:space="0" w:sz="4" w:val="single"/>
                    <w:bottom w:color="auto" w:space="0" w:sz="4" w:val="single"/>
                    <w:right w:color="auto" w:space="0" w:sz="4" w:val="single"/>
                    <w:insideH w:color="auto" w:space="0" w:sz="4" w:val="single"/>
                    <w:insideV w:color="auto" w:space="0" w:sz="4" w:val="single"/>
                </w:tblBorders>
            </w:tblPr>
            <w:tblGrid/>
           	<w:tr>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnNameWidth}"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr/>
                        <w:r>
                            <w:rPr>
                                <w:b/>
                            </w:rPr>
                            <w:t>Name</w:t>
                        </w:r>
                    </w:p>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnDefWidth}"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr/>
                        <w:r>
                            <w:rPr>
                                <w:b/>
                            </w:rPr>
                            <w:t>Definition</w:t>
                        </w:r>
                    </w:p>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnMultWidth}"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr/>
                        <w:r>
                            <w:rPr>
                                <w:b/>
                            </w:rPr>
                            <w:t>Mult.</w:t>
                        </w:r>
                    </w:p>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnTypeWidth}"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr/>
                        <w:r>
                            <w:rPr>
                                <w:b/>
                            </w:rPr>
                            <w:t>Value Type</w:t>
                        </w:r>
                    </w:p>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnRemarkWidth}"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr/>
                        <w:r>
                            <w:rPr>
                                <w:b/>
                            </w:rPr>
                            <w:t>Remarks</w:t>
                        </w:r>
                    </w:p>
				</w:tc>
            </w:tr>
           	<w:tr>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnNameWidth}"/>
	           			<w:shd w:val="clear" w:color="auto" w:fill="F0F0F0"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr/>
                        <w:r>
                            <w:t><xsl:value-of disable-output-escaping="no" select="$featuretype/name"/></w:t>
                        </w:r>
                    </w:p>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnDefWidth}"/>
	           			<w:shd w:val="clear" w:color="auto" w:fill="F0F0F0"/>
                    </w:tcPr>
                    <xsl:choose>
                    	<xsl:when test="$featuretype/definition">
                    <xsl:for-each select="$featuretype/definition">
	                    <w:p>
	                        <w:pPr/>
	                        <w:r>
	                            <w:t><xsl:value-of disable-output-escaping="no" select="."/></w:t>
	                        </w:r>
	                    </w:p>
                    </xsl:for-each>
                    	</xsl:when>
                    	<xsl:otherwise>
                    		<w:p/>
                    	</xsl:otherwise>
                    </xsl:choose>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnMultWidth}"/>
	           			<w:shd w:val="clear" w:color="auto" w:fill="F0F0F0"/>
                    </w:tcPr>
                    <w:p/>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnTypeWidth}"/>
	           			<w:shd w:val="clear" w:color="auto" w:fill="F0F0F0"/>
                    </w:tcPr>
                    <w:p/>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnRemarkWidth}"/>
	           			<w:shd w:val="clear" w:color="auto" w:fill="F0F0F0"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr/>                        
                        <w:r>
                            	<w:t></w:t>
                        </w:r>
                        	<xsl:if test="$featuretype/subtypeOf">
                        <w:r>
                            	<w:t>Subtype of:</w:t>
                        </w:r>
                    <xsl:for-each select="$featuretype/subtypeOf">
                        <xsl:variable name="type" select="."/>    
                        	<w:r><w:br/></w:r>            
                            <xsl:if test="$type/@idref and key('modelElement',$type/@idref)">
                                <!-- Create a reference to the model element. -->
                                <w:r>
                                    <w:fldChar w:fldCharType="begin"/>
                                </w:r>
                                <w:r>
                                    <xsl:element name="w:instrText">
                                        <xsl:attribute name="xml:space">preserve</xsl:attribute>
                                        <xsl:text> REF _Ref</xsl:text>
                                        <xsl:value-of select="./@idref"/>
                                        <xsl:text> \h </xsl:text>
                                    </xsl:element>
                                </w:r>
                                <w:r>
                                    <w:fldChar w:fldCharType="separate"/>
                                </w:r>
                            </xsl:if>
                            <w:r>
                                <w:t>
                                            <xsl:value-of disable-output-escaping="no" select="."/>                                                
                                </w:t>
                            </w:r>
                            <xsl:if test="$type/@idref and key('modelElement',$type/@idref)">
                                <w:r>
                                    <w:fldChar w:fldCharType="end"/>
                                </w:r>
                            </xsl:if>
                    </xsl:for-each>
                            	
                        	</xsl:if>
                    </w:p>
				</w:tc>
            </w:tr>
            <xsl:for-each select="key('modelElement',$featuretype/characterizedBy/@idref)">
                <!-- apply an alphabetical sort of feature type characteristics (attributes, relationships etc) -->
                <xsl:sort select="./name"/>
                <xsl:apply-templates mode="detail" select="."/>
            </xsl:for-each>  
        </w:tbl>
        <w:p/>
    </xsl:template>

    <xsl:template match="FeatureAttribute|RelationshipRole" mode="detail">
        <xsl:variable name="featureAtt" select="."/>
           	<w:tr>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnNameWidth}"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr/>
                        <w:r>
                            <w:t><xsl:value-of disable-output-escaping="no" select="$featureAtt/name"/></w:t>
                        </w:r>
                    </w:p>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnDefWidth}"/>
                    </w:tcPr>
                    <xsl:choose>
                    	<xsl:when test="$featureAtt/definition">
                    <xsl:for-each select="$featureAtt/definition">
	                    <w:p>
	                        <w:pPr/>
	                        <w:r>
	                            <w:t><xsl:value-of disable-output-escaping="no" select="."/></w:t>
	                        </w:r>
	                    </w:p>
                    </xsl:for-each>
                    	</xsl:when>
                    	<xsl:otherwise>
                    		<w:p/>
                    	</xsl:otherwise>
                    </xsl:choose>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnMultWidth}"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr/>
                        <w:r>
                            <w:t><xsl:value-of disable-output-escaping="no" select="$featureAtt/cardinality"/></w:t>
                        </w:r>
                    </w:p>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnTypeWidth}"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr/>
                        <xsl:if test="$featureAtt/ValueDataType">
		                    <xsl:call-template name="valuetype">
		                        <xsl:with-param name="type" select="$featureAtt/ValueDataType"/>
		                    </xsl:call-template>                        
                        </xsl:if>
                        <xsl:if test="$featureAtt/FeatureTypeIncluded">
		                    <xsl:call-template name="valuetype">
		                        <xsl:with-param name="type" select="$featureAtt/FeatureTypeIncluded"/>
		                    </xsl:call-template>                        
                        </xsl:if>
                    </w:p>
				</w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$entryTableColumnRemarkWidth}"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr/>                        
                        <w:r>
                            	<w:t></w:t>
                        </w:r>
                    </w:p>
				</w:tc>
            </w:tr>                       
    </xsl:template>
    
    <!-- TBD: merge entry and attentry templates -->
    <xsl:template name="entry">
        <xsl:param name="title"/>
        <xsl:param name="lines"/>
        <xsl:if test="$lines">
            <w:tr>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$ftypeTableColumnOneWidth}"/>
                    </w:tcPr>
                    <w:p>
                        <w:pPr>
                            <w:ind w:left="{$entryLineIndent}"/>
                        </w:pPr>
                        <w:r>
                            <w:rPr>
                                <w:b/>
                            </w:rPr>
                            <w:t><xsl:value-of disable-output-escaping="no" select="$title"/>:</w:t>
                        </w:r>
                    </w:p>
                </w:tc>
                <w:tc>
                    <w:tcPr>
                        <w:tcW w:type="pct" w:w="{$ftypeTableColumnTwoWidth}"/>
                    </w:tcPr>
                    <xsl:for-each select="$lines">
                        <xsl:variable name="line" select="."/>                
                        <w:p>
                            <xsl:if test="$line/@idref and key('modelElement',$line/@idref)">
                                <!-- Create a reference to the model element. -->
                                <w:r>
                                    <w:fldChar w:fldCharType="begin"/>
                                </w:r>
                                <w:r>
                                    <xsl:element name="w:instrText">
                                        <xsl:attribute name="xml:space">preserve</xsl:attribute>
                                        <xsl:text> REF _Ref</xsl:text>
                                        <xsl:value-of select="./@idref"/>
                                        <xsl:text> \h </xsl:text>
                                    </xsl:element>
                                </w:r>
                                <w:r>
                                    <w:fldChar w:fldCharType="separate"/>
                                </w:r>
                            </xsl:if>
                            <w:r>
                                <w:t>
                                    <!-- If this entry is about the type of a feature type, localize the $line. -->
                                    <!-- This is a workaround for avoiding the #RTREEFRAG issue when using call-template inside a with-param. -->
                                    <xsl:choose>
                                        <xsl:when test="$title = $fc.Type">
                                            <xsl:call-template name="typename">
                                                <xsl:with-param name="type" select="$line"/>
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of disable-output-escaping="no" select="."/>                                                
                                        </xsl:otherwise>                                            
                                    </xsl:choose>
                                </w:t>
                            </w:r>
                            <xsl:if test="$line/@idref and key('modelElement',$line/@idref)">
                                <w:r>
                                    <w:fldChar w:fldCharType="end"/>
                                </w:r>
                            </xsl:if>
                        </w:p>
                    </xsl:for-each>
                </w:tc>
            </w:tr>
        </xsl:if>
    </xsl:template>

	<xsl:template name="valuetype">
        <xsl:param name="type"/>
                            <xsl:if test="$type/@idref and key('modelElement',$type/@idref)">
                                <!-- Create a reference to the model element. -->
                                <w:r>
                                    <w:fldChar w:fldCharType="begin"/>
                                </w:r>
                                <w:r>
                                    <xsl:element name="w:instrText">
                                        <xsl:attribute name="xml:space">preserve</xsl:attribute>
                                        <xsl:text> REF _Ref</xsl:text>
                                        <xsl:value-of select="./@idref"/>
                                        <xsl:text> \h </xsl:text>
                                    </xsl:element>
                                </w:r>
                                <w:r>
                                    <w:fldChar w:fldCharType="separate"/>
                                </w:r>
                            </xsl:if>
                            <w:r>
                                <w:t>
                                            <xsl:value-of disable-output-escaping="no" select="$type"/>                                                
                                </w:t>
                            </w:r>
                            <xsl:if test="$type/@idref and key('modelElement',$type/@idref)">
                                <w:r>
                                    <w:fldChar w:fldCharType="end"/>
                                </w:r>
                            </xsl:if>
	</xsl:template>
	
	<xsl:template name="typename">
        <xsl:param name="type"/>        
        <xsl:choose>
            <xsl:when test="$type='Feature Type'"><xsl:value-of select="$fc.FeatureType"/></xsl:when>
            <xsl:when test="$type='Object Type'"><xsl:value-of select="$fc.ObjectType"/></xsl:when>
            <xsl:when test="$type='Data Type'"><xsl:value-of select="$fc.DataType"/></xsl:when>
            <xsl:when test="$type='Union Data Type'"><xsl:value-of select="$fc.UnionType"/></xsl:when>
            <xsl:otherwise>
                <xsl:value-of select="$type"/>
            </xsl:otherwise>
        </xsl:choose>        
    </xsl:template>
</xsl:stylesheet>
