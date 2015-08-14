<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"
  xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
  xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:sc="http://shapechange.net/functions"
  exclude-result-prefixes="sc xs xsl">
  
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
  <xsl:variable name="captionId"
    select="document($styleXmlPath)/w:styles/w:style[w:name/@w:val = 'caption']/@w:styleId"/>

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

  <!-- Define the width (in percent [not adding the '%' sign, thus the value is multiplied by 50]) for general table properties. -->
  <xsl:variable name="tableWidth">5000</xsl:variable>
  <xsl:variable name="generalTableColumnWidth">5000</xsl:variable>

  <!-- Define the width (in percent [not adding the '%' sign, thus the value is multiplied by 50]) for each of the columns in a feature type table. -->
  <xsl:variable name="ftypeTableColumnOneWidth">1500</xsl:variable>
  <xsl:variable name="ftypeTableColumnTwoWidth">3500</xsl:variable>

  <!-- Define the width (in percent [not adding the '%' sign, thus the value is multiplied by 50]) for each of the columns in a class entry table (e.g. for enumeration values). -->
  <xsl:variable name="clentryTableColumnOneWidth">1500</xsl:variable>
  <xsl:variable name="clentryTableColumnTwoWidth">3500</xsl:variable>
  
  <!-- =============================================================== -->
  <!-- Variables and functions for transformation of image information -->
  <!-- =============================================================== -->
  <xsl:variable name="horzResDpi" as="xs:integer">72</xsl:variable>
  <xsl:variable name="vertResDpi" as="xs:integer">72</xsl:variable>
  <xsl:variable name="emusPerInch" as="xs:integer">914400</xsl:variable>
  <xsl:variable name="emusPerCm" as="xs:integer">360000</xsl:variable>
  <xsl:variable name="maxWidthCm" as="xs:integer">18</xsl:variable>
  
  <xsl:function name="sc:scaleWidth" as="xs:string">
    <xsl:param name="widthPx" as="xs:integer"/>
    <xsl:param name="heightPx" as="xs:integer"/>
    <xsl:variable name="widthEmus" as="xs:double" select="$widthPx div $horzResDpi * $emusPerInch"/>
    <xsl:variable name="heightEmus" as="xs:double" select="$heightPx div $vertResDpi * $emusPerInch"/>    
    <xsl:variable name="maxWidthEmus" as="xs:double" select="$maxWidthCm * $emusPerCm"/>
    <xsl:choose>
      <xsl:when test="$widthEmus > $maxWidthEmus">
        <xsl:sequence select="format-number($maxWidthEmus,'#')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="format-number($widthEmus,'#')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
  <xsl:function name="sc:scaleHeight" as="xs:string">
    <xsl:param name="widthPx" as="xs:integer"/>
    <xsl:param name="heightPx" as="xs:integer"/>
    
    <xsl:variable name="widthEmus" as="xs:double" select="$widthPx div $horzResDpi * $emusPerInch"/>
    <xsl:variable name="heightEmus" as="xs:double" select="$heightPx div $vertResDpi * $emusPerInch"/>
    <xsl:variable name="maxWidthEmus" as="xs:double" select="$maxWidthCm * $emusPerCm"/>
    <xsl:choose>
      <xsl:when test="$widthEmus > $maxWidthEmus">
        <xsl:variable name="ratio" as="xs:double" select="$heightEmus div $widthEmus"/>
        <xsl:sequence select="format-number($maxWidthEmus * $ratio,'#')"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:sequence select="format-number($heightEmus,'#')"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>
  
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
    <!-- TBD: TOC relevant at this location for a docx catalogue? -->
    <xsl:for-each select="Package|ApplicationSchema">
      <xsl:sort select="./code"/>
      <xsl:sort select="./name"/>
      <xsl:apply-templates mode="detail" select="."/>
    </xsl:for-each>
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
<!--      <xsl:for-each select="$package/images/image">-->
      <xsl:apply-templates select="$package/images"/>
      <!--</xsl:for-each>-->
      <!-- TBD: provide a reference back to the TOC, a feature catalogue overview (TBD), a specific chapter heading (e.g. the main feature catalogue chapter heading)? -->
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
        </xsl:element>
      </w:r>
      <w:bookmarkEnd w:id="0"/>
    </w:p>
    <!--w:p/-->
    <w:tbl>
      <w:tblPr>
        <w:tblW w:type="pct">
          <xsl:attribute name="w:w">
            <xsl:value-of disable-output-escaping="no" select="$tableWidth"/>
          </xsl:attribute>
        </w:tblW>
        <w:tblBorders>
          <w:top w:color="auto" w:space="0" w:sz="4" w:val="single"/>
          <w:left w:color="auto" w:space="0" w:sz="4" w:val="single"/>
          <w:bottom w:color="auto" w:space="0" w:sz="4" w:val="single"/>
          <w:right w:color="auto" w:space="0" w:sz="4" w:val="single"/>
          <w:insideH w:color="auto" w:space="0" w:sz="4" w:val="single"/>
          <w:insideV w:color="auto" w:space="0" w:sz="0" w:val="none"/>
        </w:tblBorders>
      </w:tblPr>
      <w:tblGrid/>
      <w:tr>
        <w:tc>
          <w:tcPr>
            <w:tcW w:type="pct">
              <xsl:attribute name="w:w">
                <xsl:value-of disable-output-escaping="no" select="$generalTableColumnWidth"/>
              </xsl:attribute>
            </w:tcW>
          </w:tcPr>
          <w:p>
            <w:pPr/>
            <w:r>
              <w:rPr>
                <w:b/>
              </w:rPr>
              <w:t>
                <xsl:value-of disable-output-escaping="no" select="$featuretype/name"/>
              </w:t>
            </w:r>
          </w:p>
          <w:tbl>
            <w:tblPr>
              <w:tblW w:type="pct">
                <xsl:attribute name="w:w">
                  <xsl:value-of disable-output-escaping="no" select="$tableWidth"/>
                </xsl:attribute>
              </w:tblW>
              <w:tblBorders>
                <w:top w:color="auto" w:space="0" w:sz="0" w:val="none"/>
                <w:left w:color="auto" w:space="0" w:sz="0" w:val="none"/>
                <w:bottom w:color="auto" w:space="0" w:sz="0" w:val="none"/>
                <w:right w:color="auto" w:space="0" w:sz="0" w:val="none"/>
                <w:insideH w:color="auto" w:space="0" w:sz="0" w:val="none"/>
                <w:insideV w:color="auto" w:space="0" w:sz="0" w:val="none"/>
              </w:tblBorders>
            </w:tblPr>
            <w:tblGrid/>
            <xsl:call-template name="entry">
              <xsl:with-param name="title" select="$fc.Title"/>
              <xsl:with-param name="lines" select="$featuretype/title"/>
            </xsl:call-template>
            <xsl:call-template name="entry">
              <xsl:with-param name="title" select="$fc.Definition"/>
              <xsl:with-param name="lines" select="$featuretype/definition"/>
            </xsl:call-template>
            <xsl:call-template name="entry">
              <xsl:with-param name="title" select="$fc.Description"/>
              <xsl:with-param name="lines" select="$featuretype/description"/>
            </xsl:call-template>
            <xsl:call-template name="entry">
              <xsl:with-param name="title" select="$fc.SubtypeOf"/>
              <xsl:with-param name="lines" select="$featuretype/subtypeOf"/>
            </xsl:call-template>
            <xsl:call-template name="subtypeentry">
              <xsl:with-param name="title" select="$fc.SupertypeOf"/>
              <xsl:with-param name="types"
                select="/FeatureCatalogue/FeatureType[subtypeOf/@idref=$featuretype/@id]"/>
            </xsl:call-template>
            <xsl:call-template name="entry">
              <xsl:with-param name="title" select="$fc.Type"/>
              <xsl:with-param name="lines" select="$featuretype/type"/>
            </xsl:call-template>
            <xsl:call-template name="entry">
              <xsl:with-param name="title" select="$fc.Code"/>
              <xsl:with-param name="lines" select="$featuretype/code"/>
            </xsl:call-template>
          </w:tbl>
          <w:p/>
        </w:tc>
      </w:tr>
      <xsl:for-each select="key('modelElement',$featuretype/characterizedBy/@idref)">
        <!-- apply an alphabetical sort of feature type characteristics (attributes, relationships etc) -->
        <xsl:sort select="./name"/>
        <xsl:apply-templates mode="detail" select="."/>
      </xsl:for-each>
      <xsl:for-each select="$featuretype/constraint">
        <!-- apply an alphabetical sort of feature type constraints; constraints without name are listed first -->
        <xsl:sort select="./name"/>
        <xsl:apply-templates mode="detail" select="."/>
      </xsl:for-each>
    </w:tbl>
    <w:p/>
<!--    <xsl:for-each select="$featuretype/images/image">-->
    <xsl:apply-templates select="$featuretype/images"/>
    <!--</xsl:for-each>-->
    <!-- TBD: add reference back to package? -->
  </xsl:template>

  <xsl:template match="images">
    <xsl:if test="./image">
      <w:p>
        <w:r>
          <w:rPr>
            <w:b/>
          </w:rPr>
          <w:t>
            <xsl:value-of select="$fc.Diagrams"/>
            <xsl:text>:</xsl:text>
          </w:t>
        </w:r>
      </w:p>
    </xsl:if>
    <xsl:for-each select="./image">      
    <w:p>
      <w:pPr>
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:drawing>
          <wp:inline>
            <wp:extent>
              <xsl:attribute name="cx">
                <xsl:value-of disable-output-escaping="no" select="sc:scaleWidth(./@width,./@height)"/>
<!--                <xsl:value-of disable-output-escaping="no" select="format-number(@width * 9525,'#')"/>-->
              </xsl:attribute>
              <xsl:attribute name="cy">
                <xsl:value-of disable-output-escaping="no" select="sc:scaleHeight(./@width,./@height)"/>
<!--                <xsl:value-of disable-output-escaping="no" select="format-number(@height * 9525,'#')"/>-->
              </xsl:attribute>
            </wp:extent>
            <wp:docPr>
              <xsl:attribute name="id">
                <xsl:value-of disable-output-escaping="no" select="@idAsInt"/>
              </xsl:attribute>
              <xsl:attribute name="name">
                <xsl:value-of disable-output-escaping="no" select="@name"/>
              </xsl:attribute>
            </wp:docPr>
            <a:graphic xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main">
              <a:graphicData uri="http://schemas.openxmlformats.org/drawingml/2006/picture">
                <pic:pic xmlns:pic="http://schemas.openxmlformats.org/drawingml/2006/picture">
                  <pic:nvPicPr>
                    <pic:cNvPr>
                      <xsl:attribute name="id">
                        <xsl:value-of disable-output-escaping="no" select="@idAsInt+1"/>
                      </xsl:attribute>
                      <xsl:attribute name="name">
                        <xsl:value-of disable-output-escaping="no" select="@name"/>
                      </xsl:attribute>
                    </pic:cNvPr>
                    <pic:cNvPicPr/>
                  </pic:nvPicPr>
                  <pic:blipFill>
                    <a:blip>
                      <xsl:attribute name="cstate">
                        <xsl:text>print</xsl:text>
                      </xsl:attribute>
                      <xsl:attribute name="r:embed">
                        <xsl:value-of disable-output-escaping="no" select="@id"/>
                      </xsl:attribute>
                    </a:blip>
                    <a:stretch>
                      <a:fillRect/>
                    </a:stretch>
                  </pic:blipFill>
                  <pic:spPr>
                    <a:xfrm>
                      <a:off x="0" y="0"/>
                      <a:ext>
                        <xsl:attribute name="cx">
                          <xsl:value-of disable-output-escaping="no" select="sc:scaleWidth(./@width,./@height)"/>
                          <!--                <xsl:value-of disable-output-escaping="no" select="format-number(@width * 9525,'#')"/>-->
                        </xsl:attribute>
                        <xsl:attribute name="cy">
                          <xsl:value-of disable-output-escaping="no" select="sc:scaleHeight(./@width,./@height)"/>
                          <!--                <xsl:value-of disable-output-escaping="no" select="format-number(@height * 9525,'#')"/>-->
                        </xsl:attribute>
                      </a:ext>
                    </a:xfrm>
                    <a:prstGeom prst="rect"/>
                  </pic:spPr>
                </pic:pic>
              </a:graphicData>
            </a:graphic>
          </wp:inline>
        </w:drawing>
      </w:r>
    </w:p>
    <w:p>
      <w:pPr>
        <w:pStyle>
          <xsl:attribute name="w:val">
            <xsl:value-of disable-output-escaping="no" select="$captionId"/>
          </xsl:attribute>
        </w:pStyle>        
        <w:jc w:val="center"/>
      </w:pPr>
      <w:r>
        <w:t>Figure</w:t>
      </w:r>
      <w:r>
        <w:t xml:space="preserve"> </w:t>
      </w:r>
      <w:fldSimple w:instr=" SEQ Figure \* ARABIC ">
        <w:r>
          <w:rPr>
            <w:noProof/>
          </w:rPr>
          <!-- Do not explicitly set the figure number here - a simple complete 
            refresh of the document content in word automatically creates the figure number -->
          <w:t/>
        </w:r>
      </w:fldSimple>
      <w:r>
        <w:t xml:space="preserve"><xsl:text> - </xsl:text><xsl:value-of select="@name"/></w:t>
      </w:r>
      <w:bookmarkStart w:id="0" w:name="_GoBack"/>
      <w:bookmarkEnd w:id="0"/>
    </w:p>
    </xsl:for-each>
  </xsl:template>

  <xsl:template match="FeatureAttribute" mode="detail">
    <xsl:variable name="featureAtt" select="."/>
    <w:tr>
      <w:tc>
        <w:tcPr>
          <w:tcW w:type="pct">
            <xsl:attribute name="w:w">
              <xsl:value-of disable-output-escaping="no" select="$generalTableColumnWidth"/>
            </xsl:attribute>
          </w:tcW>
        </w:tcPr>
        <w:p>
          <w:r>
            <w:rPr>
              <w:b/>
            </w:rPr>
            <w:t>
              <xsl:value-of select="$fc.Attribute"/>
              <xsl:text>:</xsl:text>
            </w:t>
          </w:r>
        </w:p>
        <w:tbl>
          <w:tblPr>
            <w:tblW w:type="pct">
              <xsl:attribute name="w:w">
                <xsl:value-of disable-output-escaping="no" select="$tableWidth"/>
              </xsl:attribute>
            </w:tblW>
            <w:tblBorders>
              <w:top w:color="auto" w:space="0" w:sz="0" w:val="none"/>
              <w:left w:color="auto" w:space="0" w:sz="0" w:val="none"/>
              <w:bottom w:color="auto" w:space="0" w:sz="0" w:val="none"/>
              <w:right w:color="auto" w:space="0" w:sz="0" w:val="none"/>
              <w:insideH w:color="auto" w:space="0" w:sz="0" w:val="none"/>
              <w:insideV w:color="auto" w:space="0" w:sz="0" w:val="none"/>
            </w:tblBorders>
          </w:tblPr>
          <w:tblGrid/>

          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Name"/>
            <xsl:with-param name="lines" select="$featureAtt/name"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Title"/>
            <xsl:with-param name="lines" select="$featureAtt/title"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Definition"/>
            <xsl:with-param name="lines" select="$featureAtt/definition"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Description"/>
            <xsl:with-param name="lines" select="$featureAtt/description"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Voidable"/>
            <xsl:with-param name="lines" select="$featureAtt/voidable"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Code"/>
            <xsl:with-param name="lines" select="$featureAtt/code"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Multiplicity"/>
            <xsl:with-param name="lines" select="$featureAtt/cardinality"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.ValueType"/>
            <xsl:with-param name="lines" select="$featureAtt/ValueDataType"/>
          </xsl:call-template>
          <xsl:if test="$featureAtt/ValueDomainType = 1">
            <xsl:call-template name="clentry">
              <xsl:with-param name="title" select="$fc.Values"/>
              <xsl:with-param name="values"
                select="key('modelElement',$featureAtt/enumeratedBy/@idref)"/>
            </xsl:call-template>
          </xsl:if>
        </w:tbl>
        <w:p/>
      </w:tc>
    </w:tr>
  </xsl:template>

  <xsl:template match="constraint" mode="detail">
    <w:tr>
      <w:tc>
        <w:tcPr>
          <w:tcW w:type="pct">
            <xsl:attribute name="w:w">
              <xsl:value-of disable-output-escaping="no" select="$generalTableColumnWidth"/>
            </xsl:attribute>
          </w:tcW>
        </w:tcPr>
        <w:p>
          <w:r>
            <w:rPr>
              <w:b/>
            </w:rPr>
            <w:t>
              <xsl:value-of select="$fc.Constraint"/>
              <xsl:text>:</xsl:text>
            </w:t>
          </w:r>
        </w:p>
        <w:tbl>
          <w:tblPr>
            <w:tblW w:type="pct">
              <xsl:attribute name="w:w">
                <xsl:value-of disable-output-escaping="no" select="$tableWidth"/>
              </xsl:attribute>
            </w:tblW>
            <w:tblBorders>
              <w:top w:color="auto" w:space="0" w:sz="0" w:val="none"/>
              <w:left w:color="auto" w:space="0" w:sz="0" w:val="none"/>
              <w:bottom w:color="auto" w:space="0" w:sz="0" w:val="none"/>
              <w:right w:color="auto" w:space="0" w:sz="0" w:val="none"/>
              <w:insideH w:color="auto" w:space="0" w:sz="0" w:val="none"/>
              <w:insideV w:color="auto" w:space="0" w:sz="0" w:val="none"/>
            </w:tblBorders>
          </w:tblPr>
          <w:tblGrid/>

          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Name"/>
            <xsl:with-param name="lines" select="name"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Description"/>
            <xsl:with-param name="lines" select="description"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Expression"/>
            <xsl:with-param name="lines" select="expression"/>
          </xsl:call-template>
        </w:tbl>
        <w:p/>
      </w:tc>
    </w:tr>
  </xsl:template>

  <xsl:template match="RelationshipRole" mode="detail">
    <xsl:variable name="featureAtt" select="."/>

    <w:tr>
      <w:tc>
        <w:tcPr>
          <w:tcW w:type="pct">
            <xsl:attribute name="w:w">
              <xsl:value-of disable-output-escaping="no" select="$generalTableColumnWidth"/>
            </xsl:attribute>
          </w:tcW>
        </w:tcPr>
        <w:p>
          <w:r>
            <w:rPr>
              <w:b/>
            </w:rPr>
            <w:t>
              <xsl:value-of select="$fc.AssociationRole"/>
            </w:t>
          </w:r>
        </w:p>
        <w:tbl>
          <w:tblPr>
            <w:tblW w:type="pct">
              <xsl:attribute name="w:w">
                <xsl:value-of disable-output-escaping="no" select="$tableWidth"/>
              </xsl:attribute>
            </w:tblW>
          </w:tblPr>
          <w:tblGrid/>

          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Name"/>
            <xsl:with-param name="lines" select="$featureAtt/name"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Title"/>
            <xsl:with-param name="lines" select="$featureAtt/title"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Definition"/>
            <xsl:with-param name="lines" select="$featureAtt/definition"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Description"/>
            <xsl:with-param name="lines" select="$featureAtt/description"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Voidable"/>
            <xsl:with-param name="lines" select="$featureAtt/voidable"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Code"/>
            <xsl:with-param name="lines" select="$featureAtt/code"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Multiplicity"/>
            <xsl:with-param name="lines" select="$featureAtt/cardinality"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.ValueType"/>
            <xsl:with-param name="lines" select="$featureAtt/FeatureTypeIncluded"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.AssociationClass"/>
            <xsl:with-param name="lines"
              select="key('modelElement',@id=$featureAtt/relation/@idref)/associationClass"/>
          </xsl:call-template>
        </w:tbl>
        <w:p/>
      </w:tc>
    </w:tr>
  </xsl:template>

  <xsl:template match="FeatureOperation" mode="detail">
    <xsl:variable name="featureAtt" select="."/>

    <w:tr>
      <w:tc>
        <w:tcPr>
          <w:tcW w:type="auto" w:w="0"/>
        </w:tcPr>
        <w:p>
          <w:r>
            <w:rPr>
              <w:b/>
            </w:rPr>
            <w:t>
              <xsl:value-of select="$fc.Operation"/>
            </w:t>
          </w:r>
        </w:p>
        <w:tbl>
          <w:tblPr>
            <w:tblW w:type="pct">
              <xsl:attribute name="w:w">
                <xsl:value-of disable-output-escaping="no" select="$tableWidth"/>
              </xsl:attribute>
            </w:tblW>
          </w:tblPr>
          <w:tblGrid/>

          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Name"/>
            <xsl:with-param name="lines" select="$featureAtt/name"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Title"/>
            <xsl:with-param name="lines" select="$featureAtt/title"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Definition"/>
            <xsl:with-param name="lines" select="$featureAtt/definition"/>
          </xsl:call-template>
          <xsl:call-template name="attentry">
            <xsl:with-param name="title" select="$fc.Description"/>
            <xsl:with-param name="lines" select="$featureAtt/description"/>
          </xsl:call-template>
        </w:tbl>
        <w:p/>
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
          <xsl:choose>
            <xsl:when test="$lines">
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
            </xsl:when>
            <xsl:otherwise>
              <!-- ensure that a w:p is there before a </w:tc> -->
              <w:p/>
            </xsl:otherwise>
          </xsl:choose>
        </w:tc>
      </w:tr>
    </xsl:if>
  </xsl:template>

  <xsl:template name="subtypeentry">
    <xsl:param name="title"/>
    <xsl:param name="types"/>
    <xsl:if test="$types">
      <w:tr>
        <w:tc>
          <w:tcPr>
            <w:tcW w:type="auto" w:w="0"/>
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
          <xsl:choose>
            <xsl:when test="$types">
              <xsl:for-each select="$types">
                <xsl:sort select="./code"/>
                <xsl:sort select="./name"/>
                <w:p>
                  <w:r>
                    <w:fldChar w:fldCharType="begin"/>
                  </w:r>
                  <w:r>
                    <xsl:element name="w:instrText">
                      <xsl:attribute name="xml:space">preserve</xsl:attribute>
                      <xsl:text> REF _Ref</xsl:text>
                      <xsl:value-of select="@id"/>
                      <xsl:text> \h </xsl:text>
                    </xsl:element>
                  </w:r>
                  <w:r>
                    <w:fldChar w:fldCharType="separate"/>
                  </w:r>
                  <w:r>
                    <w:t xml:space="preserve"><xsl:value-of disable-output-escaping="no" select="name"/></w:t>
                  </w:r>
                  <w:r>
                    <w:fldChar w:fldCharType="end"/>
                  </w:r>
                </w:p>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <!-- ensure that a w:p is there before a </w:tc> -->
              <w:p/>
            </xsl:otherwise>
          </xsl:choose>
        </w:tc>
      </w:tr>
    </xsl:if>
  </xsl:template>

  <!-- TBD: merge entry and attentry templates -->
  <xsl:template name="attentry">
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
          <xsl:choose>
            <xsl:when test="$lines">
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
                  <xsl:if test="$line/@category">
                    <!-- TBD: localize text based upon category value? -->
                    <w:r>
                      <xsl:element name="w:t">
                        <xsl:attribute name="xml:space">preserve</xsl:attribute>
                        <xsl:text> (</xsl:text>
                        <xsl:call-template name="typename">
                          <!-- Here the @category value is in lower case; in order for the @category to also be translated, the same case needs to be used in @category and FeatureType/type-->
                          <xsl:with-param name="type" select="./@category"/>
                        </xsl:call-template>
                        <xsl:text>)</xsl:text>
                      </xsl:element>
                      <!--                                    <w:t xml:space="preserve"> (<xsl:value-of select="./@category"/>)</w:t>-->
                    </w:r>
                  </xsl:if>
                </w:p>
              </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
              <!-- ensure that a w:p is there before a </w:tc> -->
              <w:p/>
            </xsl:otherwise>
          </xsl:choose>
        </w:tc>
      </w:tr>
    </xsl:if>
  </xsl:template>

  <xsl:template name="clentry">
    <xsl:param name="title"/>
    <xsl:param name="values"/>
    <xsl:if test="$values">
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
              <w:t>
                <xsl:value-of select="$fc.Values"/>
              </w:t>
            </w:r>
          </w:p>
        </w:tc>
        <w:tc>
          <w:tcPr>
            <w:tcW w:type="pct" w:w="{$ftypeTableColumnTwoWidth}"/>
          </w:tcPr>
          <w:tbl>
            <w:tblPr>
              <w:tblW w:type="auto" w:w="0"/>
              <w:tblInd w:type="dxa" w:w="{$clentryTableIndent}"/>
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
            <xsl:for-each select="$values">
              <w:tr>
                <xsl:variable name="value" select="."/>
                <w:tc>
                  <w:tcPr>
                    <w:tcW w:type="pct" w:w="{$clentryTableColumnOneWidth}"/>
                  </w:tcPr>
                  <w:p>
                    <w:r>
                      <w:t>
                        <xsl:value-of disable-output-escaping="no" select="./code"/>
                      </w:t>
                    </w:r>
                  </w:p>
                </w:tc>
                <w:tc>
                  <w:tcPr>
                    <w:tcW w:type="pct" w:w="{$clentryTableColumnTwoWidth}"/>
                  </w:tcPr>
                  <xsl:if test="not(./code = ./label)">
                    <w:p>
                      <w:r>
                        <w:rPr>
                          <w:b/>
                        </w:rPr>
                        <w:t>
                          <xsl:value-of disable-output-escaping="no" select="./label"/>
                        </w:t>
                      </w:r>
                    </w:p>
                  </xsl:if>
                  <xsl:if test="./definition">
                    <xsl:for-each select="./definition">
                      <w:p>
                        <w:r>
                          <w:t>
                            <xsl:value-of disable-output-escaping="no" select="."/>
                          </w:t>
                        </w:r>
                      </w:p>
                    </xsl:for-each>
                  </xsl:if>
                  <xsl:if test="./description">
                    <xsl:for-each select="./description">
                      <w:p>
                        <w:r>
                          <w:t>
                            <xsl:value-of disable-output-escaping="no" select="."/>
                          </w:t>
                        </w:r>
                      </w:p>
                    </xsl:for-each>
                  </xsl:if>
                  <xsl:if test="not(not(./code = ./label) or ./definition or ./description)">
                    <!-- ensure that a w:p is there before a </w:tc> -->
                    <w:p/>
                  </xsl:if>
                </w:tc>
              </w:tr>
            </xsl:for-each>
          </w:tbl>
          <w:p/>
        </w:tc>
      </w:tr>
    </xsl:if>
  </xsl:template>

  <xsl:template name="typename">
    <xsl:param name="type"/>
    <xsl:choose>
      <xsl:when test="$type='Feature Type'">
        <xsl:value-of select="$fc.FeatureType"/>
      </xsl:when>
      <xsl:when test="$type='Object Type'">
        <xsl:value-of select="$fc.ObjectType"/>
      </xsl:when>
      <xsl:when test="$type='Data Type'">
        <xsl:value-of select="$fc.DataType"/>
      </xsl:when>
      <xsl:when test="$type='Union Data Type'">
        <xsl:value-of select="$fc.UnionType"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$type"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>
</xsl:stylesheet>
