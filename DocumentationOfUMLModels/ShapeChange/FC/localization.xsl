<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <!-- (c) 2001-2013 interactive instruments GmbH, Bonn -->
    
  <!-- ==================== -->
  <!-- Internationalization -->
  <!-- ==================== -->
  <!--
        The values for the following parameters are automatically set by ShapeChange to their default values, 
        unless they are overridden via the ShapeChange configuration file. 
    -->
  <xsl:param name="lang">en</xsl:param>
  <xsl:param name="locMsgFile">localizationMessages.xml</xsl:param>
  
  <!-- When executed with ShapeChange, the absolute URI to the locMsgFile is automatically determined via a custom URI resolver. -->
  <xsl:variable name="localizationMessages" select="document($locMsgFile)"/>
  
  <xsl:variable name="fc.Abstract"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Abstract']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.ApplicationSchema"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.ApplicationSchema']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.AssociationClass"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.AssociationClass']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.AssociationRole"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.AssociationRole']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Attribute"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Attribute']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.backToPackage"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.backToPackage']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.backToToc"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.backToToc']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Code"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Code']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Constraint"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Constraint']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.DataType"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.DataType']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.DataTypes"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.DataTypes']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Date"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Date']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Definition"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Definition']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Description"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Description']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Diagram"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Diagram']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Diagrams"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Diagrams']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Documentation"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Documentation']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Expression"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Expression']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.FeatureCatalogue"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.FeatureCatalogue']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.FeatureType"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.FeatureType']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.FeatureTypes"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.FeatureTypes']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.FullName"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.FullName']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.GeneratedBy"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.GeneratedBy']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.GeneratedOn"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.GeneratedOn']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Multiplicity"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Multiplicity']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Name"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Name']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.ObjectType"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.ObjectType']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.ObjectTypes"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.ObjectTypes']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Operation"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Operation']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Package"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Package']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Packages"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Packages']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Parent"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Parent']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.ParentPackage"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.ParentPackage']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.ResponsibleOrganization"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.ResponsibleOrganization']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Scope"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Scope']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.SubPackage"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.SubPackage']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.SubtypeOf"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.SubtypeOf']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.SupertypeOf"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.SupertypeOf']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Title"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Title']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Toc"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Toc']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Type"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Type']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.true"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.true']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.UnionType"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.UnionType']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.UnionTypes"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.UnionTypes']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.unnamed"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.unnamed']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Values"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Values']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.ValueType"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.ValueType']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Version"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Version']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.Voidable"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.Voidable']/text[contains(@lang,$lang)]"/></xsl:variable>
  
  <!-- Frame-HTML specific messages -->
  <xsl:variable name="fc.frame.Alert"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.Alert']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.AlertText"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.AlertText']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.AllTypes"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.AllTypes']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.ApplicationSchemaPackages"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.ApplicationSchemaPackages']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.AttributesAndAssociationRoles"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.AttributesAndAssociationRoles']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.HideListedValues"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.HideListedValues']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.JavaScriptDisabled"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.JavaScriptDisabled']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.LinkTo"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.LinkTo']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.none"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.none']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.NonFrameVersion"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.NonFrameVersion']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.NoRelevantTypes"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.NoRelevantTypes']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.Overview"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.Overview']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.OverviewOfCharacteristics"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.OverviewOfCharacteristics']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.RelevantTypes"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.RelevantTypes']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.SeeListedValues"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.SeeListedValues']/text[contains(@lang,$lang)]"/></xsl:variable>
  <xsl:variable name="fc.frame.ValueName"><xsl:value-of select="$localizationMessages/messages/message[@id='fc.frame.ValueName']/text[contains(@lang,$lang)]"/></xsl:variable>
  
</xsl:stylesheet>
