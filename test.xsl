<?xml version="1.0" encoding="UTF-8" ?>
<transform version="1.0" xmlns="http://www.w3.org/1999/XSL/Transform">
<output method="text" encoding="utf-8"/>

<template match="score-partwise">

	<!--

	<for-each select="part[1]/measure[direction]"> 
			<text>{"BarIndex":</text>
			<value-of select="position()-1"/>
			<text>,"CommentKey":</text>
			<for-each select="direction[1]/direction-type/*">
				<choose>
					<when test="name()='words' or name()='rehearsal'">
						<value-of select="substring(.,1,10)"/>
					</when>
					<when test="self::*">
						<value-of select="substring(name(),1,10)"/>
					</when>
				</choose>
			</for-each>
			<text>}</text>
			<if test="position()!=last()">
				<text>,</text>
			</if>
	</for-each>
	-->
	<apply-templates select="part[1]/measure[1]"/>
	
  </template>
  
  <template match="measure">
		
		<param name="repeat-counter">0</param>
		<param name="al-coda" select="false()"/>
		<param name="measure-number">1</param>
		Measure # (pos)<value-of select="position()"/><text> (num)</text><value-of select="@number"/><text> (counter)</text><value-of select="$measure-number"/>(repeat)<value-of select="$repeat-counter"/>
		
		<choose>
		<!-- not needed, was just testing
			<when test="barline/repeat[@direction='forward']">
				Repeat (forward)
				<apply-templates select="following-sibling::measure[1]">
					<with-param name="repeat-counter" select="$repeat-counter"/>
					<with-param name="al-coda" select="$al-coda"/>
					<with-param name="measure-number" select="$measure-number + 1"/>
				</apply-templates>
			</when>
		-->
		
			<when test="barline/repeat[@direction='backward'] and $repeat-counter=0">
			Repeat (backward)
				<choose>
					<when test="preceding-sibling::measure/barline/repeat[@direction='forward']">
				    from forward
						<apply-templates select="preceding-sibling::measure[barline[repeat[@direction='forward']]]">
							<with-param name="repeat-counter" select="$repeat-counter+1"/>
							<with-param name="al-coda" select="$al-coda"/>
							<with-param name="measure-number" select="$measure-number + 1"/>
						</apply-templates>
					</when>
					<otherwise>
					from first
						<apply-templates select="../measure[1]">
							<with-param name="repeat-counter" select="$repeat-counter+1"/>
							<with-param name="al-coda" select="$al-coda"/>
							<with-param name="measure-number" select="$measure-number + 1"/>
						</apply-templates>
					</otherwise>
				</choose>
			</when>
			
			<when test="direction/direction-type/words='D.C. al Coda' and not($al-coda)">
			D.C. al Coda
				<apply-templates select="../measure[1]">
					<with-param name="repeat-counter" select="0"/>
					<with-param name="al-coda" select="true()"/>
					<with-param name="measure-number" select="$measure-number + 1"/>
				</apply-templates>
			</when>
		
			<when test="substring(direction/direction-type/words,1,4)='D.C.' and not($al-coda)">
			<!-- not sure entirely safe, but 'overloading' $al-coda to mean any of the D.C. or D.S. instructions
			     if it's 'D.C.' but not 'al Coda' (NOT what the test above is testing, btw)
				 assuming that the D.C. instruction will be to take a subsequent repeat,
				 and the $repeat-counter parameter will drive where it goes in the end -->
			<value-of select="direction/direction-type/words"/>
				<apply-templates select="../measure[1]">
					<with-param name="repeat-counter" select="$repeat-counter + 1"/>
					<with-param name="al-coda" select="true()"/>
					<!-- maybe not quite, may want to track da-capo, dal-segno, and al-coda separately -->
					<with-param name="measure-number" select="$measure-number + 1"/>
				</apply-templates>
			</when>
				
			<when test="direction/direction-type/words='D.S. al Coda' and not($al-coda)">
			D.S. al Coda
				<apply-templates select="preceding-sibling::measure[direction[direction-type[segno]]]">
					<with-param name="repeat-counter" select="0"/>
					<with-param name="al-coda" select="true()"/>
					<with-param name="measure-number" select="$measure-number + 1"/>
				</apply-templates>
			</when>

			<when test="following-sibling::measure[1]/barline/ending[@type='start']">
			Ending
				<apply-templates select="following-sibling::measure[barline[ending[@type='start' and @number=($repeat-counter+1)]]]">
					<with-param name="repeat-counter" select="$repeat-counter"/>
					<with-param name="al-coda" select="$al-coda"/>
					<with-param name="measure-number" select="$measure-number + 1"/>
				</apply-templates>
			</when>
	
			<when test="direction/direction-type/coda and $al-coda and following-sibling::measure/direction/direction-type/coda">
			coda
				<apply-templates select="following-sibling::measure[direction[direction-type[coda]]]">
					<with-param name="repeat-counter" select="$repeat-counter"/>
					<with-param name="al-coda" select="true()"/>
					<with-param name="measure-number" select="$measure-number + 1"/>
				</apply-templates>
			</when>
			
			<otherwise>
				<apply-templates select="following::measure[1]">
					<with-param name="repeat-counter" select="$repeat-counter"/>
					<with-param name="al-coda" select="$al-coda"/>
					<with-param name="measure-number" select="$measure-number + 1"/>
				</apply-templates>
			</otherwise>
			
		</choose>
		
  
  </template>
  
</transform>

