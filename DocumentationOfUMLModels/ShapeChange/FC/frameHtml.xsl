<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="2.0">
    <!-- (c) 2001-2013 interactive instruments GmbH, Bonn -->
    
    <!-- ==================== -->
    <!-- Imports and Includes -->
    <!-- ==================== -->
    
    <!-- include the stylesheet with localization variables -->
    <xsl:include href="localization.xsl"/>
    
    <!-- ========= -->
    <!-- Debugging -->
    <!-- ========= -->
    <xsl:variable name="debug" select="false()"/>
 
    <!-- ================= -->
    <!-- Output parameters -->
    <!-- ================= -->  
    <xsl:output name="html5" method="html" indent="yes" doctype-system="about:legacy-compat"/>
    
    <!-- The name of the output directory is automatically set by ShapeChange (the value of the 'outputFilename' parameter from the configuration is actually used). -->
    <xsl:param name="outputdir"/>
    <xsl:param name="includeGeneratedByStatement" select="false()"/>
    <xsl:param name="includeGeneratedOn" select="true()"/>
    
    <!-- ================= -->
    <!-- Catalogue content -->
    <!-- ================= -->
    <!-- The term used to denote a feature type, e.g. "Spatial Object Type" in INSPIRE. Defaults to "Feature Type". -->
    <xsl:param name="featureTypeSynonym"/>
    <!-- The path to the catalogue tmp xml is set automatically by ShapeChange. -->
    <xsl:param name="catalogXmlPath"/>
    <!-- When executed with ShapeChange, the absolute URI to the catalog XML is automatically determined via a custom URI resolver. -->
    <xsl:variable name="catalogDocument" select="document($catalogXmlPath)"/>
    <xsl:variable name="catalog" select="$catalogDocument/FeatureCatalogue"/>
    <xsl:variable name="appSchemaName" select="$catalog/name"/>
    
    <xsl:key name="modelElement" match="/*/*[@id]" use="@id"/>
    
    <xsl:param name="packages" as="element()*">
        <xsl:for-each select="$catalog/*[local-name() = 'ApplicationSchema' or local-name() = 'Package']">
            <package>
                <id><xsl:value-of select="@id"/></id>
                <xsl:if test="parent">
                    <parentId><xsl:value-of select="parent/@idref"/></parentId>
                </xsl:if>
                <name><xsl:value-of select="name"/></name>
                <type><xsl:value-of select="local-name()"/></type>
                <path>
                    <xsl:call-template name="packagepath">
                        <xsl:with-param name="package-node" select="."/>
                    </xsl:call-template>
                </path>
                <backpath>
                    <xsl:call-template name="backpath">
                        <xsl:with-param name="package-node" select="."/>
                    </xsl:call-template>                    
                </backpath>
            </package>            
        </xsl:for-each>        
    </xsl:param>
            
    <!-- ======================== -->
    <!-- Transformation templates -->
    <!-- ======================== -->  
    <xsl:template match="/">
        <!-- Create the index.html -->
        <xsl:result-document href="{$outputdir}/index.html" format="html5">
            <xsl:if test="$debug"><xsl:message>Generating index.html ...</xsl:message></xsl:if>            
            <html lang="{$lang}">                
                <xsl:if test="$includeGeneratedOn">
                	<xsl:comment>Created by ShapeChange on <xsl:value-of  select="current-dateTime()"/></xsl:comment>               
                </xsl:if>
                <head>                    
                    <title>
                        <xsl:value-of select="$fc.FeatureCatalogue"/>
                        <xsl:text> </xsl:text>
                        <xsl:value-of select="$appSchemaName"/>
                    </title>
                    <meta http-equiv="Content-type" content="text/html; charset=UTF-8"></meta>
                    <link rel="stylesheet" type="text/css" href="stylesheet.css" title="Style"/>
                </head>
                <body>
                    <div class="bannerDiv"><iframe src="banner.html" name="bannerFrame" title="Banner" scrolling="no" frameborder="0"></iframe></div>
                    <div class="contentDiv">
                        <table class="overallContent">
                            <tr class="sidepanelTopRow">
                                <td><iframe src="overview-frame.html" name="packageListFrame" title="All Packages"></iframe></td>
                                <td class="contentCell" rowspan="2">
                                    <iframe src="overview-summary.html" name="classFrame" title="Package and class descriptions">
                                        <h2><xsl:value-of select="$fc.frame.Alert"/></h2>
                                        <p/><xsl:value-of select="$fc.frame.AlertText"/><br/>
                                        <xsl:value-of select="$fc.frame.LinkTo"/><a href="overview-summary.html"><xsl:value-of select="$fc.frame.NonFrameVersion"/></a>
                                    </iframe>
                                </td>
                            </tr>
                            <tr class="sidepanelBottomRow">
                                <td><iframe src="allclasses-frame.html" name="packageFrame" title="All classes"></iframe></td>
                            </tr>
                        </table>
                    </div>
                </body>
            </html>
            <xsl:if test="$debug"><xsl:message>--- done</xsl:message></xsl:if>
        </xsl:result-document>
        
        <!-- Create the banner.html -->
        <xsl:result-document href="{$outputdir}/banner.html" format="html5">
            <xsl:if test="$debug"><xsl:message>Generating banner.html ...</xsl:message></xsl:if>
            <html lang="{$lang}">
                <xsl:if test="$includeGeneratedOn">
                	<xsl:comment>Created by ShapeChange on <xsl:value-of  select="current-dateTime()"/></xsl:comment>
                </xsl:if>
                <head>                    
                    <title><xsl:value-of select="$appSchemaName"/></title>
                    <meta http-equiv="Content-type" content="text/html; charset=UTF-8"></meta>
                    <link rel="stylesheet" type="text/css" href="stylesheet.css" title="Style"/>
                </head>
                
                <header>
                    <h1 class="banner"><xsl:value-of select="$appSchemaName"/></h1>
                </header>                                
            </html>
            <xsl:if test="$debug"><xsl:message>--- done</xsl:message></xsl:if>
        </xsl:result-document>

        <!-- Create the overview-frame.html -->
        <xsl:result-document href="{$outputdir}/overview-frame.html" format="html5">
            <xsl:if test="$debug"><xsl:message>Generating overview-frame.html ...</xsl:message></xsl:if>
            <html lang="{$lang}">
            	<xsl:if test="$includeGeneratedOn">
                	<xsl:comment>Created by ShapeChange on <xsl:value-of  select="current-dateTime()"/></xsl:comment>
                </xsl:if>
                <head>
                    <title><xsl:value-of select="$appSchemaName"/><xsl:text> - </xsl:text><xsl:value-of select="$fc.frame.Overview"/></title>
                    <meta http-equiv="Content-type" content="text/html; charset=UTF-8"/>
                    <link rel="stylesheet" type="text/css" href="stylesheet.css" title="Style"/>
                </head>
                <body>
                    <div/>
                    <h1 class="sidepanel"><xsl:value-of select="$appSchemaName"/></h1>
                    <ul>
                    <li>
                        <a target="classFrame" href="overview-summary.html"><xsl:value-of select="$fc.frame.Overview"/></a>
                    </li>                    
                    <li>
                        <a target="packageFrame" href="allclasses-frame.html"><xsl:value-of select="$fc.frame.AllTypes"/></a>
                    </li>
                    </ul>
                    <xsl:for-each select="$packages[type = 'ApplicationSchema']">
                        <xsl:sort select="./name"/>
                        <xsl:variable name="appSchemaPackage" select="."/>
                        <h2 class="sidepanel"><xsl:value-of select="$appSchemaPackage/name"/></h2>
                        <ul>                            
                            <xsl:for-each select="$packages[id = $appSchemaPackage/id or (type = 'Package' and starts-with(path,$appSchemaPackage/path))]">
                                <xsl:sort select="./path"/>
                                <li>
                                    <a href="{concat(./path,'/package-frame.html')}"
                                        target="packageFrame">
                                        <xsl:value-of select="./path"/>
                                    </a>                                
                                </li>
                            </xsl:for-each>
                        </ul>                        
                    </xsl:for-each>
                </body>
            </html>
            <xsl:if test="$debug"><xsl:message>--- done</xsl:message></xsl:if>
        </xsl:result-document>

        <!-- Create the overview-summary.html -->
        <xsl:result-document href="{$outputdir}/overview-summary.html" format="html5">
            <xsl:if test="$debug"><xsl:message>Generating overview-summary.html ...</xsl:message></xsl:if>
            <html lang="{$lang}">
                <xsl:if test="$includeGeneratedOn">
                	<xsl:comment>Created by ShapeChange on <xsl:value-of  select="current-dateTime()"/></xsl:comment>
                </xsl:if>
                <head>
                    <title><xsl:value-of select="$appSchemaName"/><xsl:text> - </xsl:text><xsl:value-of select="$fc.frame.Overview"/></title>
                    <meta http-equiv="Content-type" content="text/html; charset=UTF-8"/>
                    <link rel="stylesheet" type="text/css" href="stylesheet.css" title="Style"/>
                </head>
                <body>
                    <div id="header">
                        <!-- Place to add a header with links, for example to switch to non-framebased view -->
                    </div>
                    <div id="main">                    
                        <!-- Create the feature catalogue description. -->                        
                        <xsl:apply-templates select="$catalog" mode="description"/>        
                        <!-- Create the package overview. -->
                        <h2><xsl:value-of select="$fc.frame.ApplicationSchemaPackages"/></h2>
                        <table class="colored">
                            <tr>
                                <th><xsl:value-of select="$fc.Package"/></th>
                                <th><xsl:value-of select="$fc.Definition"/></th>
                                <th><xsl:value-of select="$fc.Description"/></th>
                            </tr>                        
                            <xsl:for-each select="$packages">
                                <xsl:sort select="path"/>
                                <tr>
                                    <xsl:choose>
                                        <xsl:when test="position() mod 2 = 1">
                                            <xsl:attribute name="class">odd</xsl:attribute>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:attribute name="class">even</xsl:attribute>
                                        </xsl:otherwise>
                                    </xsl:choose>
                                    <td>
                                        <a href="{concat(path,'/package-summary.html')}">
                                            <xsl:value-of select="path"/>
                                        </a>
                                    </td>                                    
                                    <xsl:choose>
                                        <xsl:when test="key('modelElement',id,$catalog)/definition">
                                            <td>
                                                <xsl:value-of select="key('modelElement',id,$catalog)/definition"/>
                                            </td>
                                        </xsl:when>
                                        <xsl:otherwise><td>-</td></xsl:otherwise>
                                    </xsl:choose>
                                    <xsl:choose>
                                        <xsl:when test="key('modelElement',id,$catalog)/description">
                                            <td>
                                                <xsl:value-of select="key('modelElement',id,$catalog)/description"/>
                                            </td>
                                        </xsl:when>
                                        <xsl:otherwise><td>-</td></xsl:otherwise>
                                    </xsl:choose>                                    
                                </tr>
                            </xsl:for-each>
                        </table>
                    </div>
                    <div/>
                    <div id="footer">
                        <!-- Created by, etc. -->
                        <xsl:if test="$includeGeneratedByStatement">
                            <xsl:call-template name="generatedByStatement"/>
                        </xsl:if>
                    </div>
                </body>
            </html>
            <xsl:if test="$debug"><xsl:message>--- done</xsl:message></xsl:if>
        </xsl:result-document>

        <!-- Create the allclasses-frame.html -->
        <xsl:result-document href="{$outputdir}/allclasses-frame.html" format="html5">
            <xsl:if test="$debug"><xsl:message>Generating allclasses-frame.html ...</xsl:message></xsl:if>
            <html lang="{$lang}">
                <xsl:if test="$includeGeneratedOn">
                	<xsl:comment>Created by ShapeChange on <xsl:value-of  select="current-dateTime()"/></xsl:comment>
                </xsl:if>
                <head>
                    <title><xsl:value-of select="$fc.frame.AllTypes"/> (<xsl:value-of select="$appSchemaName"/>)</title>
                    <meta http-equiv="Content-type" content="text/html; charset=UTF-8"/>
                    <link rel="stylesheet" type="text/css" href="stylesheet.css" title="Style"/>
                </head>
                <body>
                    <h1 class="sidepanel"><xsl:value-of select="$fc.frame.AllTypes"/></h1>
                    <div>
                        <xsl:if test="$catalog/FeatureType[type = $featureTypeSynonym]">
                            <div>
                                <!-- If featureTerm is other than 'Feature Type', heading can be adjusted by customizing the localization messages. -->
                                <h2 class="sidepanel"><xsl:value-of select="$fc.FeatureTypes"/></h2>
                                <ul>                                
                                    <xsl:for-each select="$catalog/FeatureType[type = $featureTypeSynonym]">
                                        <xsl:sort select="name"/>
                                        <xsl:apply-templates select="." mode="allClassesFrame_TypeListEntry"/>
                                    </xsl:for-each>
                                </ul>
                            </div>
                        </xsl:if>
                        <xsl:if test="$catalog/FeatureType[type = 'Object Type']">
                            <div>
                                <h2 class="sidepanel"><xsl:value-of select="$fc.ObjectTypes"/></h2>
                                <ul>                                
                                    <xsl:for-each select="$catalog/FeatureType[type = 'Object Type']">
                                        <xsl:sort select="name"/>
                                        <xsl:apply-templates select="." mode="allClassesFrame_TypeListEntry"/>
                                    </xsl:for-each>
                                </ul>
                            </div>
                        </xsl:if>
                        <xsl:if test="$catalog/FeatureType[type = 'Data Type']">
                            <div>
                                <h2 class="sidepanel"><xsl:value-of select="$fc.DataTypes"/></h2>
                                <ul>                                
                                    <xsl:for-each select="$catalog/FeatureType[type = 'Data Type']">
                                        <xsl:sort select="name"/>
                                        <xsl:apply-templates select="." mode="allClassesFrame_TypeListEntry"/>
                                    </xsl:for-each>
                                </ul>
                            </div>
                        </xsl:if>
                        <xsl:if test="$catalog/FeatureType[type = 'Union Data Type']">
                            <div>
                                <h2 class="sidepanel"><xsl:value-of select="$fc.UnionTypes"/></h2>
                                <ul>                                
                                    <xsl:for-each select="$catalog/FeatureType[type = 'Union Data Type']">
                                        <xsl:sort select="name"/>
                                        <xsl:apply-templates select="." mode="allClassesFrame_TypeListEntry"/>
                                    </xsl:for-each>
                                </ul>
                            </div>
                        </xsl:if>
                        <xsl:if test="not($catalog/FeatureType)">
                            <br/>
                            <div>
                                <p>
                                    <i><xsl:value-of select="$fc.frame.NoRelevantTypes"/></i>
                                </p>
                            </div>
                        </xsl:if>
                    </div>
                </body>
            </html>
            <xsl:if test="$debug"><xsl:message>--- done</xsl:message></xsl:if>
        </xsl:result-document>
        
        <!-- Now automatically create the html files for each package and each relevant type. -->
        <xsl:apply-templates select="$catalog/*[local-name() = 'ApplicationSchema' or local-name() = 'Package']"/>
    </xsl:template>
    
    <xsl:template match="ApplicationSchema|Package">
        <xsl:variable name="package" select="."/>
        <xsl:variable name="path" select="$packages[id = $package/@id]/path"/>
        <xsl:variable name="backpath" select="$packages[id = $package/@id]/backpath"/>
                
        <!-- Create the package-frame.html -->
        <xsl:result-document href="{concat($outputdir,'/',$path,'/package-frame.html')}" format="html5">
            <xsl:if test="$debug"><xsl:message><xsl:text>Generating </xsl:text><xsl:value-of select="concat($outputdir,'/',$path,'/package-frame.html')"/><xsl:text> ...</xsl:text></xsl:message></xsl:if>
            <html lang="{$lang}">
                <xsl:if test="$includeGeneratedOn">
                	<xsl:comment>Created by ShapeChange on <xsl:value-of  select="current-dateTime()"/></xsl:comment>
                </xsl:if>
                <head>
                    <title><xsl:value-of select="$packages[id = ./@id]/path"/> (<xsl:value-of select="$appSchemaName"/>)</title>
                    <meta http-equiv="Content-type" content="text/html; charset=UTF-8"/>
                    <link rel="stylesheet" type="text/css" href="{concat($backpath,'stylesheet.css')}" title="Style"/>
                </head>
                <body>
                    <h1 class="sidepanel"><xsl:value-of select="name"/></h1>
                    <ul>
                        <li>
                            <a href="{concat($backpath,$path,'/package-summary.html')}" target="classFrame">Overview</a>
                        </li>
                    </ul>
                    <xsl:if test="$catalog/FeatureType[package[@idref=$package/@id] and type = $featureTypeSynonym]">
                        <div>
                            <!-- If featureTerm is other than 'Feature Type', heading can be adjusted by customizing the localization messages. -->
                            <h2 class="sidepanel"><xsl:value-of select="$fc.FeatureTypes"/></h2>
                            <ul>                                
                                <xsl:for-each select="$catalog/FeatureType[package[@idref=$package/@id] and type = $featureTypeSynonym]">
                                    <xsl:sort select="name"/>
                                    <xsl:apply-templates select="." mode="packageFrame_TypeListEntry"/>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </xsl:if>
                    <xsl:if test="$catalog/FeatureType[package[@idref=$package/@id] and type = 'Object Type']">
                        <div>
                            <h2 class="sidepanel"><xsl:value-of select="$fc.ObjectTypes"/></h2>
                            <ul>                                
                                <xsl:for-each select="$catalog/FeatureType[package[@idref=$package/@id] and type = 'Object Type']">
                                    <xsl:sort select="name"/>
                                    <xsl:apply-templates select="." mode="packageFrame_TypeListEntry"/>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </xsl:if>
                    <xsl:if test="$catalog/FeatureType[package[@idref=$package/@id] and type = 'Data Type']">
                        <div>
                            <h2 class="sidepanel"><xsl:value-of select="$fc.DataTypes"/></h2>
                            <ul>                                
                                <xsl:for-each select="$catalog/FeatureType[package[@idref=$package/@id] and type = 'Data Type']">
                                    <xsl:sort select="name"/>
                                    <xsl:apply-templates select="." mode="packageFrame_TypeListEntry"/>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </xsl:if>
                    <xsl:if test="$catalog/FeatureType[package[@idref=$package/@id] and type = 'Union Data Type']">
                        <div>
                            <h2 class="sidepanel"><xsl:value-of select="$fc.UnionTypes"/></h2>
                            <ul>                                
                                <xsl:for-each select="$catalog/FeatureType[package[@idref=$package/@id] and type = 'Union Data Type']">
                                    <xsl:sort select="name"/>
                                    <xsl:apply-templates select="." mode="packageFrame_TypeListEntry"/>
                                </xsl:for-each>
                            </ul>
                        </div>
                    </xsl:if>
                    <xsl:if test="not($catalog/FeatureType[package[@idref=$package/@id]])">
                        <br/>
                        <div>
                            <p>
                                <i><xsl:value-of select="$fc.frame.NoRelevantTypes"/></i>
                            </p>
                        </div>
                    </xsl:if>
                </body>
            </html>
            <xsl:if test="$debug"><xsl:message>--- done</xsl:message></xsl:if>
        </xsl:result-document>
        
        <!-- Create the package-summary.html -->
        <xsl:result-document href="{concat($outputdir,'/',$path,'/package-summary.html')}" format="html5">
            <xsl:if test="$debug"><xsl:message><xsl:text>Generating </xsl:text><xsl:value-of select="concat($outputdir,'/',$path,'/package-summary.html')"/><xsl:text> ...</xsl:text></xsl:message></xsl:if>
            <html lang="{$lang}">
                <xsl:if test="$includeGeneratedOn">
                	<xsl:comment>Created by ShapeChange on <xsl:value-of  select="current-dateTime()"/></xsl:comment>
                </xsl:if>
                <head>
                    <title><xsl:value-of select="$packages[id = ./@id]/path"/> (<xsl:value-of select="$appSchemaName"/>)</title>
                    <meta http-equiv="Content-type" content="text/html; charset=UTF-8"/>
                    <link rel="stylesheet" type="text/css" href="{concat($backpath,'stylesheet.css')}" title="Style"/>
                </head>
                <body>                    
                    <div id="header">
                        <!-- Place to add a header with links, for example to switch to non-framebased view -->
                    </div>                    
                    <div id="main">                         
                        <xsl:choose>
                            <xsl:when test="parent">
                                <p>
                                    <h1>
                                        <xsl:value-of select="$fc.Package"/>
                                        <xsl:text>: </xsl:text>
                                        <xsl:value-of select="name" disable-output-escaping="yes"/>
                                    </h1>
                                </p>
                                <p class="indent">
                                    <xsl:value-of select="$fc.Parent"/>
                                    <xsl:text>: </xsl:text>
                                    <a href="{concat($backpath,$packages[id = $package/parent/@idref]/path,'/package-summary.html')}">
                                        <xsl:value-of select="key('modelElement',$package/parent/@idref)/name"
                                            disable-output-escaping="yes"/>
                                    </a>
                                </p>
                            </xsl:when>
                            <xsl:otherwise>
                                <p>
                                    <h1>
                                        <xsl:value-of select="$fc.ApplicationSchema"/>
                                        <xsl:text>: </xsl:text>
                                        <xsl:value-of select="name" disable-output-escaping="yes"/>
                                    </h1>
                                </p>
                            </xsl:otherwise>
                        </xsl:choose> 
                        <xsl:if test="taggedValues/generationDateTime">
                            <p class="indent">
                                <xsl:value-of select="$fc.GeneratedOn"/>
                                <xsl:text>: </xsl:text>
                                <xsl:value-of select="taggedValues/generationDateTime" disable-output-escaping="yes"/>
                            </p>
                        </xsl:if>
                        <xsl:for-each select="$catalog/Package[parent/@idref=$package/@id]">
                            <xsl:sort select="./code"/>
                            <xsl:sort select="./name"/>
                            <xsl:variable name="subpackage" select="."/>                                        
                            <p class="indent">
                                <xsl:value-of select="$fc.SubPackage"/>
                                <xsl:text>: </xsl:text>
                                <a href="{concat($backpath,$packages[id = $subpackage/@id]/path,'/package-summary.html')}">
                                    <xsl:value-of select="name" disable-output-escaping="yes"/>
                                </a>
                            </p>
                        </xsl:for-each>                        
                        <tr>
                        <xsl:choose>
                            <xsl:when test="$catalog/FeatureType/package[@idref=$package/@id]">                         
                             <p>
                                 <h2><xsl:value-of select="$fc.frame.RelevantTypes"/><xsl:text>:</xsl:text></h2>
                             </p>
                            <!-- Create table with sorted list of types belonging to this package, including their description and definition. -->
                            <table class="colored">
                                <tr>
                                    <th><xsl:value-of select="$fc.Name"/></th>
                                    <th><xsl:value-of select="$fc.Type"/></th>
                                    <th><xsl:value-of select="$fc.Definition"/></th>
                                    <th><xsl:value-of select="$fc.Description"/></th>
                                </tr>         
                                <xsl:for-each select="$catalog/FeatureType[package[@idref=$package/@id]]">
                                    <xsl:sort data-type="number" order="ascending"
                                        select="(number(type=$featureTypeSynonym) * 1) +
                                        (number(type='Object Type') * 2) +
                                        (number(type='Data Type') * 3) +
                                        (number(type='Union Data Type') * 4)"
                                    />
                                    <xsl:sort select="name"/>
                                    <tr>
                                        <xsl:choose>
                                            <xsl:when test="position() mod 2 = 1">
                                                <xsl:attribute name="class">odd</xsl:attribute>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:attribute name="class">even</xsl:attribute>
                                            </xsl:otherwise>
                                        </xsl:choose>                                                                       
                                        <xsl:apply-templates select="." mode="packageSummary_TypeListEntry">
                                            <xsl:with-param name="backpath" select="$backpath"/>
                                            <xsl:with-param name="path" select="$path"/>
                                        </xsl:apply-templates>
                                    </tr>
                                </xsl:for-each>                                
                            </table>
                            </xsl:when>
                            <xsl:otherwise>
                                <p><h2><xsl:value-of select="$fc.frame.RelevantTypes"/><xsl:text>:</xsl:text></h2></p>
                                <p class="indent"><b><i><xsl:value-of select="$fc.frame.none"/></i></b></p>
                            </xsl:otherwise>
                        </xsl:choose>
                        </tr> 
                    </div>                    
                    <div/>
                    <div id="footer">
                        <!-- Created by, etc. -->
                        <xsl:if test="$includeGeneratedByStatement">
                            <xsl:call-template name="generatedByStatement"/>
                        </xsl:if>
                    </div>
                </body>
            </html>
            <xsl:if test="$debug"><xsl:message>--- done</xsl:message></xsl:if>
        </xsl:result-document>
        
        <xsl:apply-templates select="$catalog/FeatureType[package/@idref=$package/@id]" mode="typeDetailHtml"/>
        
    </xsl:template>
    
    <xsl:template match="FeatureType" mode="packageFrame_TypeListEntry">
        <xsl:variable name="FeatureType" select="."/>
        <li>
            <a href="{concat(name,'.html')}" target="classFrame">
                <xsl:choose>
                    <xsl:when test="isAbstract">
                        <i><xsl:value-of select="name"/></i>
                    </xsl:when>
                    <xsl:otherwise><xsl:value-of select="name"/></xsl:otherwise>
                </xsl:choose>                
            </a>
        </li>            
    </xsl:template>
    
    <xsl:template match="FeatureType" mode="allClassesFrame_TypeListEntry">
        <xsl:variable name="FeatureType" select="."/>
        <li>
            <a href="{concat($packages[id = $FeatureType/package/@idref]/path,'/',name,'.html')}" title="type in {$packages[id = $FeatureType/package/@idref]/path}" target="classFrame">
                <xsl:choose>
                    <xsl:when test="isAbstract">
                        <i><xsl:value-of select="name"/></i>
                    </xsl:when>
                    <xsl:otherwise><xsl:value-of select="name"/></xsl:otherwise>
                </xsl:choose> 
            </a>
        </li>  
    </xsl:template>
    
    <xsl:template match="FeatureType" mode="packageSummary_TypeListEntry">
        <xsl:param name="backpath"/>
        <xsl:param name="path"/>        
        <td>
            <a href="{concat($backpath,$path,'/',name,'.html')}">
                <xsl:choose>
                    <xsl:when test="isAbstract">
                        <i><xsl:value-of select="name"/></i>
                    </xsl:when>
                    <xsl:otherwise><xsl:value-of select="name"/></xsl:otherwise>
                </xsl:choose> 
            </a>
        </td>
        <td><xsl:value-of select="type"/></td>            
        <xsl:choose>
            <xsl:when test="definition">
                <td>
                    <xsl:value-of select="definition"/>
                </td>
            </xsl:when>
            <xsl:otherwise><td align="center">-</td></xsl:otherwise>
        </xsl:choose>       
        <xsl:choose>
            <xsl:when test="description">
                <td>
                    <xsl:value-of select="description"/>
                </td>
            </xsl:when>
            <xsl:otherwise><td align="center">-</td></xsl:otherwise>
        </xsl:choose>          
    </xsl:template>
    
    <xsl:template match="FeatureType" mode="typeDetailHtml">
        <xsl:variable name="featuretype" select="."/>
        <xsl:variable name="path" select="$packages[id = $featuretype/package/@idref]/path"/>
        <xsl:variable name="backpath" select="$packages[id = $featuretype/package/@idref]/backpath"/>
        
        <!-- Create the html page with all details for this type. -->
        <xsl:result-document href="{concat($outputdir,'/',$path,'/',name,'.html')}" format="html5">
            <xsl:if test="$debug"><xsl:message><xsl:text>Generating </xsl:text><xsl:value-of select="concat($outputdir,'/',$path,'/',name,'.html')"/><xsl:text> ...</xsl:text></xsl:message></xsl:if>
            <html lang="{$lang}">
                <xsl:if test="$includeGeneratedOn">
                	<xsl:comment>Created by ShapeChange on <xsl:value-of  select="current-dateTime()"/></xsl:comment>
                </xsl:if>
                <head>
                    <title><xsl:value-of select="$packages[id = ./@id]/path"/> (<xsl:value-of select="$appSchemaName"/>)</title>
                    <meta http-equiv="Content-type" content="text/html; charset=UTF-8"/>
                    <link rel="stylesheet" type="text/css" href="{concat($backpath,'stylesheet.css')}" title="Style"/>
                    <script language="javascript" type="text/javascript"> 
                        <xsl:text>function toggle(elementToShowHideById, elementToSwitchTextIn) {
                            var ele = document.getElementById(elementToShowHideById);
                            var text = document.getElementById(elementToSwitchTextIn);
                            if(ele.style.display == "block") {
                                ele.style.display = "none";
                                text.innerHTML = "</xsl:text><xsl:value-of select="$fc.frame.SeeListedValues"/><xsl:text>";
                            }
                            else {
                                ele.style.display = "block";
                                text.innerHTML = "</xsl:text><xsl:value-of select="$fc.frame.HideListedValues"/><xsl:text>";
                            }
                       }</xsl:text> 
                    </script>
                    <noscript>
                        <div><xsl:value-of select="$fc.frame.JavaScriptDisabled"/></div>
                    </noscript>
                </head>
                <body>                    
                    <h1 id="top">      
                        <xsl:if test="$featuretype/type">                            
                            <xsl:call-template name="typename">
                                <xsl:with-param name="type" select="$featuretype/type"/>
                            </xsl:call-template>
                            <xsl:text>: </xsl:text>
                        </xsl:if>
                        <xsl:choose>
                            <xsl:when test="$featuretype/isAbstract">
                                <i>
                                    <xsl:value-of select="$featuretype/name" disable-output-escaping="yes"/>
                                </i>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:value-of select="$featuretype/name" disable-output-escaping="yes"/>
                            </xsl:otherwise>
                        </xsl:choose>                        
                    </h1>
                    <table>
                        <tr>
                            <td>
                                <table>  
                                    <xsl:if test="$featuretype/taggedValues/name">
                                        <xsl:call-template name="entry"> 
                                            <xsl:with-param name="title" select="$fc.FullName"/>
                                            <xsl:with-param name="lines" select="$featuretype/taggedValues/name"/> 
                                        </xsl:call-template>
                                    </xsl:if>
                                    <xsl:call-template name="packageentry">
                                        <xsl:with-param name="title" select="$fc.Package"/>
                                        <xsl:with-param name="package" select="$featuretype/package"/> 
                                    </xsl:call-template>
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
                                        <xsl:with-param name="backpath" select="$backpath"/>
                                    </xsl:call-template>
                                    <xsl:call-template name="subtypeentry">
                                        <xsl:with-param name="title" select="$fc.SupertypeOf"/>
                                        <xsl:with-param name="types" select="$catalog/FeatureType[subtypeOf/@idref=$featuretype/@id]"/>
                                        <xsl:with-param name="backpath" select="$backpath"/>
                                    </xsl:call-template>
                                    <xsl:call-template name="entry">
                                        <xsl:with-param name="title" select="$fc.Type"/>
                                        <xsl:with-param name="lines" select="$featuretype/type"/>
                                    </xsl:call-template>
                                    <xsl:if test="$featuretype/isAbstract">
                                     <xsl:call-template name="entry">
                                         <xsl:with-param name="title" select="$fc.Abstract"/>
                                         <xsl:with-param name="lines" select="$fc.true"/>
                                     </xsl:call-template> 
                                    </xsl:if>
                                    <xsl:call-template name="entry">
                                        <xsl:with-param name="title" select="$fc.Code"/>
                                        <xsl:with-param name="lines" select="$featuretype/code"/>
                                    </xsl:call-template>   
                                </table>
                            </td>
                        </tr>
                        
                        <!-- If the type has properties (attributes or association roles) or operations, provide a brief tabular overview. -->
                        <xsl:if test="key('modelElement',$featuretype/characterizedBy/@idref)">
                        <tr>
                            <td>
                                <div>
                                    <p>
                                        <h2><xsl:value-of select="$fc.frame.OverviewOfCharacteristics"/><xsl:text>:</xsl:text></h2>
                                    </p>        
                                </div>
                                <br/>
                                <div class="indent">
                                    <xsl:choose>
                                        <xsl:when test="key('modelElement',$featuretype/characterizedBy/@idref)">
                                            <table class="colored">
                                                <caption><xsl:value-of select="$fc.frame.AttributesAndAssociationRoles"/></caption>
                                                <tr>
                                                    <th><xsl:value-of select="$fc.Name"/></th>
                                                    <th><xsl:value-of select="$fc.Type"/></th>
                                                    <th><xsl:value-of select="$fc.Multiplicity"/></th>
                                                </tr>
                                                <xsl:for-each select="key('modelElement',$featuretype/characterizedBy/@idref)">
                                                    <xsl:sort select="name"/>
                                                    <xsl:variable name="property" select="."/>
                                                    <tr>
                                                        <xsl:choose>
                                                            <xsl:when test="position() mod 2 = 1">
                                                                <xsl:attribute name="class">odd</xsl:attribute>
                                                            </xsl:when>
                                                            <xsl:otherwise>
                                                                <xsl:attribute name="class">even</xsl:attribute>
                                                            </xsl:otherwise>
                                                        </xsl:choose>  
                                                        <td>
                                                            <a href="{concat($backpath,$path,'/',$featuretype/name,'.html#',$property/@id)}">                                                        
                                                                <xsl:value-of disable-output-escaping="yes" select="$property/name"/>                                                      
                                                            </a>
                                                        </td>
                                                        <td>
                                                            <xsl:choose>
                                                                <xsl:when test="$property[local-name() = 'FeatureAttribute']">
                                                                    <xsl:choose>
                                                                        <xsl:when test="$property/ValueDataType/@idref and key('modelElement',$property/ValueDataType/@idref)">                
                                                                            <a href="{concat($backpath,$packages[id = key('modelElement',$property/ValueDataType/@idref,$catalog)/package/@idref]/path,'/',key('modelElement',$property/ValueDataType/@idref,$catalog)/name,'.html')}">
                                                                                <xsl:value-of select="ValueDataType"/>
                                                                            </a>               
                                                                        </xsl:when>
                                                                        <xsl:otherwise>                
                                                                            <xsl:value-of select="$property/ValueDataType"/>            
                                                                        </xsl:otherwise>
                                                                    </xsl:choose>                                                                    
                                                                </xsl:when>
                                                                <xsl:otherwise>
                                                                    <!-- Then we have a RelationshipRole -->
                                                                    <xsl:choose>
                                                                        <xsl:when test="$property/FeatureTypeIncluded/@idref and key('modelElement',$property/FeatureTypeIncluded/@idref)">                
                                                                            <a href="{concat($backpath,$packages[id = key('modelElement',$property/FeatureTypeIncluded/@idref,$catalog)/package/@idref]/path,'/',key('modelElement',$property/FeatureTypeIncluded/@idref,$catalog)/name,'.html')}">
                                                                                <xsl:value-of select="FeatureTypeIncluded"/>
                                                                            </a>               
                                                                        </xsl:when>
                                                                        <xsl:otherwise>                
                                                                            <xsl:value-of select="$property/FeatureTypeIncluded"/>            
                                                                        </xsl:otherwise>
                                                                    </xsl:choose> 
                                                                </xsl:otherwise>
                                                            </xsl:choose>                                                    
                                                        </td>                                                       
                                                        <td><xsl:value-of select="$property/cardinality"/></td>
                                                    </tr>
                                                </xsl:for-each>
                                            </table>
                                        </xsl:when>
                                        <xsl:otherwise><i>none</i></xsl:otherwise>
                                    </xsl:choose>
                                </div>
                            <!-- TBD: table for operations (which are not contained in tmp xml...) -->           
                            </td>
                        </tr>
                        </xsl:if>
                        
                        <xsl:for-each select="key('modelElement',$featuretype/characterizedBy/@idref)">
                            <!-- apply an alphabetical sort of feature type characteristics (attributes, relationships etc) -->
                            <xsl:sort select="./name"/>
                            <xsl:apply-templates mode="detail" select=".">
                                <xsl:with-param name="backpath" select="$backpath"/>
                            </xsl:apply-templates>
                        </xsl:for-each>           
                        <xsl:for-each select="$featuretype/constraint">
                            <!-- apply an alphabetical sort of feature type constraints; constraints without name are listed first -->
                            <xsl:sort select="./name"/>
                            <xsl:apply-templates mode="detail" select="."/>
                        </xsl:for-each>      
                    </table>
                    <div class="clearing"/>
                    <div id="footer">
                        <!-- Created by, etc. -->
                        <xsl:if test="$includeGeneratedByStatement">
                            <xsl:call-template name="generatedByStatement"/>
                        </xsl:if>
                    </div>
                </body>
            </html>
            <xsl:if test="$debug"><xsl:message>--- done</xsl:message></xsl:if>
        </xsl:result-document>      
    </xsl:template>

    <xsl:template name="packagepath">
        <xsl:param name="package-node" as="element()"/>        
        <xsl:if test="$package-node/parent">
            <xsl:call-template name="packagepath">
                <xsl:with-param name="package-node" select="key('modelElement',$package-node/parent/@idref)"/>                
            </xsl:call-template>
            <xsl:text>/</xsl:text>
        </xsl:if>
        <xsl:value-of select="$package-node/name"/>
    </xsl:template>
    
    <!-- Computes the path back to the root folder, necessary to determine the amount of /.. to prepend when referring to CSS or other files. -->
    <xsl:template name="backpath">
        <xsl:param name="package-node" as="element()"/>     
        <xsl:text>../</xsl:text>
        <xsl:if test="$package-node/parent">
            <xsl:call-template name="backpath">
                <xsl:with-param name="package-node" select="key('modelElement',$package-node/parent/@idref)"/>                
            </xsl:call-template>            
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="packageentry">
        <xsl:param name="title"/>
        <xsl:param name="package"/>
        <xsl:variable name="backpath" select="$packages[id = $package/@idref]/backpath"/>
        <xsl:if test="$package">
            <tr>
                <td>
                    <p>
                        <h2><xsl:value-of select="$title" disable-output-escaping="yes"/>:</h2>
                    </p>
                    <p class="indent">
                        <a href="{concat($backpath,$packages[id = $package/@idref]/path,'/','package-summary.html')}">
                                    <xsl:value-of disable-output-escaping="yes" select="key('modelElement',$package/@idref,$catalog)/name"/>                                                
                        </a>                               
                    </p>
                </td>
            </tr>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="entry">
        <xsl:param name="title"/>
        <xsl:param name="lines"/>
        <xsl:param name="backpath"/>
        <xsl:if test="$lines">
            <tr>
                <td>
                    <p>
                        <h2><xsl:value-of select="$title" disable-output-escaping="yes"/>:</h2>
                    </p>
                    <xsl:for-each select="$lines">
                        <xsl:variable name="line" select="."/>
                        <p class="indent">
                            <xsl:choose>
                                <xsl:when test="$line/@idref and key('modelElement',$line/@idref)">                
                                    <a href="{concat($backpath,$packages[id = key('modelElement',$line/@idref,$catalog)/package/@idref]/path,'/',key('modelElement',$line/@idref,$catalog)/name,'.html')}">
                                        <!-- If this entry is about the type of a feature type, localize the $line. -->
                                        <!-- This is a workaround for avoiding the #RTREEFRAG issue when using call-template inside a with-param. -->
                                        <xsl:choose>
                                            <xsl:when test="$title = $fc.Type">
                                                <xsl:call-template name="typename">
                                                    <xsl:with-param name="type" select="$line"/>
                                                </xsl:call-template>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of disable-output-escaping="yes" select="."/>                                                
                                            </xsl:otherwise>                                            
                                        </xsl:choose>
                                    </a>               
                                </xsl:when>
                                <xsl:otherwise>                
                                    <!-- If this entry is about the type of a feature type, localize the $line. -->
                                    <!-- This is a workaround for avoiding the #RTREEFRAG issue when using call-template inside a with-param. -->
                                    <xsl:choose>
                                        <xsl:when test="$title = $fc.Type">
                                            <xsl:call-template name="typename">
                                                <xsl:with-param name="type" select="$line"/>
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of disable-output-escaping="yes" select="."/>                                                
                                        </xsl:otherwise>                                            
                                    </xsl:choose>               
                                </xsl:otherwise>
                            </xsl:choose>
                        </p>
                    </xsl:for-each>
                </td>
            </tr>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="subtypeentry">
        <xsl:param name="title"/>
        <xsl:param name="types"/>
        <xsl:param name="backpath"/>
        <xsl:if test="$types">
            <tr>
                <td>
                    <p>
                        <h2><xsl:value-of select="$title" disable-output-escaping="yes"/>:</h2>
                    </p>
                    <xsl:for-each select="$types">
                        <xsl:sort select="./code"/>
                        <xsl:sort select="./name"/>
                        <xsl:variable name="type" select="."/>
                        <p class="indent">
                            <a href="{concat($backpath,$packages[id = $type/package/@idref]/path,'/',$type/name,'.html')}">                                
                                <xsl:value-of select="$type/name" disable-output-escaping="yes"/>
                            </a>
                        </p>
                    </xsl:for-each>
                </td>
            </tr>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="attentry">
        <xsl:param name="title"/>
        <xsl:param name="lines"/>
        <xsl:param name="backpath"/>
        <xsl:if test="$lines">
            <tr>
                <td>
                    <p class="indent title">
                        <xsl:value-of select="$title" disable-output-escaping="yes"/>:
                    </p>
                </td>
                <td>
                    <xsl:for-each select="$lines">
                        <xsl:variable name="line" select="."/>
                        <p>
                            <xsl:choose>
                                <xsl:when test="$line/@idref and key('modelElement',$line/@idref)">                
                                    <a href="{concat($backpath,$packages[id = key('modelElement',$line/@idref,$catalog)/package/@idref]/path,'/',key('modelElement',$line/@idref,$catalog)/name,'.html')}">
                                        
                                        <!-- If this entry is about the type of a feature type, localize the $line. -->
                                        <!-- This is a workaround for avoiding the #RTREEFRAG issue when using call-template inside a with-param. -->
                                        <xsl:choose>
                                            <xsl:when test="$title = $fc.Type">
                                                <xsl:call-template name="typename">
                                                    <xsl:with-param name="type" select="$line"/>
                                                </xsl:call-template>
                                            </xsl:when>
                                            <xsl:otherwise>
                                                <xsl:value-of disable-output-escaping="yes" select="."/>                                                
                                            </xsl:otherwise>                                            
                                        </xsl:choose>
                                    </a>                
                                </xsl:when>             
                                <xsl:otherwise>                
                                    <!-- If this entry is about the type of a feature type, localize the $line. -->
                                    <!-- This is a workaround for avoiding the #RTREEFRAG issue when using call-template inside a with-param. -->
                                    <xsl:choose>
                                        <xsl:when test="$title = $fc.Type">
                                            <xsl:call-template name="typename">
                                                <xsl:with-param name="type" select="$line"/>
                                            </xsl:call-template>
                                        </xsl:when>
                                        <xsl:otherwise>
                                            <xsl:value-of disable-output-escaping="yes" select="."/>                                                
                                        </xsl:otherwise>                                            
                                    </xsl:choose>
                                </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="$line/@category">
                                <xsl:text> (</xsl:text>
                                <xsl:call-template name="typename">
                                    <!-- Here the @category value is in lower case; in order for the @category to also be translated, the same case needs to be used in @category and FeatureType/type-->
                                    <xsl:with-param name="type" select="./@category"/>
                                </xsl:call-template>
                                <xsl:text>)</xsl:text>
                            </xsl:if>
                        </p>
                    </xsl:for-each>
                </td>
            </tr>
        </xsl:if>
    </xsl:template>
    
    <xsl:template match="constraint" mode="detail">
        <tr>
            <td>
                <p>
                    <h2><xsl:value-of select="$fc.Constraint"/>:</h2>
                </p>
                <table>
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
                </table>
            </td>
        </tr>
    </xsl:template>
    
    <xsl:template match="RelationshipRole" mode="detail">
        <xsl:variable name="featureAtt" select="."/>
        <xsl:variable name="backpath" select="$packages[id = key('modelElement',$featureAtt/FeatureTypeIncluded/@idref,$catalog)/package/@idref]/backpath"/>
        <tr>
            <td>
                <p>
                    <h2>
                        <a>
                            <xsl:attribute name="name">
                                <xsl:value-of select="$featureAtt/@id"/>
                            </xsl:attribute>
                            <xsl:value-of select="$fc.AssociationRole"/>:
                        </a>
                    </h2>
                </p>
                <p class="small"><a href="#top">back to top</a></p>
                <table>
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
                        <xsl:with-param name="backpath" select="$backpath"/>
                    </xsl:call-template>
                    <xsl:call-template name="attentry">
                        <xsl:with-param name="title" select="$fc.AssociationClass"/>
                        <xsl:with-param name="lines"
                            select="key('modelElement',@id=$featureAtt/relation/@idref)/associationClass"/>
                        <xsl:with-param name="backpath" select="$backpath"/>
                    </xsl:call-template>
                </table>
            </td>
        </tr>
    </xsl:template>
    <xsl:template match="FeatureOperation" mode="detail">
        <xsl:variable name="featureAtt" select="."/>
        <tr>
            <td>
                <p>
                    <h2>
                        <a>
                            <xsl:attribute name="name">
                                <xsl:value-of select="$featureAtt/@id"/>
                            </xsl:attribute>
                            <xsl:value-of select="$fc.Operation"/>:
                        </a>
                    </h2>
                </p>
                <p class="small"><a href="#top">back to top</a></p>
                <table>
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
                </table>
            </td>
        </tr>
    </xsl:template>
    
    <xsl:template match="FeatureAttribute" mode="detail">
        <xsl:param name="backpath"/>
        <xsl:variable name="featureAtt" select="."/>
        <tr>
            <td>
                <p>
                    <h2>
                        <a name="{$featureAtt/@id}">
                            <xsl:value-of select="$fc.Attribute"/>:               
                        </a>
                    </h2>
                </p>
                <p class="small"><a href="#top">back to top</a></p>
                <table>
                    <xsl:call-template name="attentry">
                        <xsl:with-param name="title" select="$fc.Name"/>
                        <xsl:with-param name="lines" select="$featureAtt/name"/>
                    </xsl:call-template>
                    <xsl:if test="$featureAtt/taggedValues/name">
                        <xsl:call-template name="attentry"> 
                            <xsl:with-param name="title" select="$fc.FullName"/>
                            <xsl:with-param name="lines" select="$featureAtt/taggedValues/name"/> 
                        </xsl:call-template>
                    </xsl:if>
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
                        <xsl:with-param name="backpath" select="$backpath"/>
                    </xsl:call-template>
                    <xsl:if test="$featureAtt/ValueDomainType = 1">
                        <xsl:if test="key('modelElement',$featureAtt/enumeratedBy/@idref)">
                            <tr>
                                <td>
                                    <p class="indent title">
                                        <xsl:value-of select="$fc.Values"/>:
                                    </p>
                                </td>
                                <td border="0">
                                    <a>
                                        <xsl:attribute name="id"><xsl:value-of select="concat($featureAtt/@id,'_listedValueLink')"/></xsl:attribute>
                                        <xsl:attribute name="href">
                                            <xsl:value-of select='concat("javascript:toggle(&apos;",concat($featureAtt/@id,"_listedValueContent"),"&apos;,&apos;",concat($featureAtt/@id,"_listedValueLink"),"&apos;);")'/>
                                        </xsl:attribute>
                                        <xsl:value-of select="$fc.frame.SeeListedValues"/>
                                    </a>
                                    <div id="{concat($featureAtt/@id,'_listedValueContent')}" style="display: none">                                       
                                        <table class="colored">
                                            <tr>
                                                <th><xsl:value-of select="$fc.frame.ValueName"/></th>
                                                <th><xsl:value-of select="$fc.Documentation"/></th> 
                                            </tr>
                                            <xsl:for-each select="key('modelElement',$featureAtt/enumeratedBy/@idref)">
                                                <xsl:variable name="value" select="."/>
                                                <tr>
                                                    <xsl:choose>
                                                        <xsl:when test="position() mod 2 = 1">
                                                            <xsl:attribute name="class">odd</xsl:attribute>
                                                        </xsl:when>
                                                        <xsl:otherwise>
                                                            <xsl:attribute name="class">even</xsl:attribute>
                                                        </xsl:otherwise>
                                                    </xsl:choose>                 
                                                    <td>
                                                        <p>
                                                            <xsl:value-of select="./code" disable-output-escaping="yes"/>
                                                        </p>
                                                    </td>
                                                    <td>
                                                        <xsl:if test="not(./code = ./label)">
                                                            <p>
                                                                <b>
                                                                    <xsl:value-of select="./label" disable-output-escaping="yes"/>
                                                                </b>
                                                            </p>
                                                        </xsl:if>
                                                        <xsl:if test="./definition">
                                                            <xsl:for-each select="./definition">
                                                                <p>
                                                                    <xsl:value-of select="." disable-output-escaping="yes"/>
                                                                </p>
                                                            </xsl:for-each>
                                                        </xsl:if>
                                                        <xsl:if test="./description">
                                                            <xsl:for-each select="./description">
                                                                <p>
                                                                    <xsl:value-of select="." disable-output-escaping="yes"/>
                                                                </p>
                                                            </xsl:for-each>
                                                        </xsl:if>
                                                    </td>
                                                </tr>
                                            </xsl:for-each>
                                        </table>
                                    </div>
                                </td>
                            </tr>
                        </xsl:if>
                    </xsl:if>
                </table>
            </td>
        </tr>
    </xsl:template>
    
    <!-- ============================================= -->
    <!-- Candidates for refactoring into a utility XSL -->
    <!-- ============================================= -->
    
    <xsl:template match="FeatureCatalogue" mode="description">
        <!-- Creates the feature catalogue description. -->
        <h1><xsl:value-of select="name"
            disable-output-escaping="yes"/><xsl:text> - </xsl:text><xsl:value-of select="$fc.frame.Overview"/>
        </h1>
        <h2><xsl:value-of select="$fc.Description"/></h2>
        <p>
            <b><xsl:value-of select="$fc.Version"/>:</b>
        </p>
        <p class="indent">
            <xsl:value-of select="versionNumber" disable-output-escaping="yes"/>
        </p>
        <p>
            <b><xsl:value-of select="$fc.Date"/>:</b>
        </p>
        <p class="indent">
            <xsl:value-of select="versionDate" disable-output-escaping="yes"/>
        </p>
        <p>
            <b><xsl:value-of select="$fc.Scope"/>:</b>
        </p>
        <xsl:for-each select="scope">
            <p class="indent">
                <xsl:value-of select="." disable-output-escaping="yes"/>
            </p>
        </xsl:for-each>
        <p>
            <b><xsl:value-of select="$fc.ResponsibleOrganization"/>:</b>
        </p>
        <p class="indent">
            <xsl:value-of select="producer" disable-output-escaping="yes"/>
        </p>
    </xsl:template>
    
    <xsl:template name="generatedByStatement">
        <p align="center">
            <small><xsl:value-of select="$fc.GeneratedBy"/><xsl:text> </xsl:text><a href="http://shapechange.net"
                >ShapeChange</a></small>
        </p>
    </xsl:template>
    
    <xsl:template name="typename">
        <xsl:param name="type"/>
        <xsl:choose>
            <xsl:when test="$type=$featureTypeSynonym"><xsl:value-of select="$fc.FeatureType"/></xsl:when>
            <xsl:when test="$type='Object Type'"><xsl:value-of select="$fc.ObjectType"/></xsl:when>
            <xsl:when test="$type='Data Type'"><xsl:value-of select="$fc.DataType"/></xsl:when>
            <xsl:when test="$type='Union Data Type'"><xsl:value-of select="$fc.UnionType"/></xsl:when>
            <xsl:otherwise><xsl:value-of select="$type"/></xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
