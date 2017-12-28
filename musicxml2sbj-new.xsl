<?xml version="1.0" encoding="UTF-8" ?>
<transform version="1.0" xmlns="http://www.w3.org/1999/XSL/Transform">
<output method="text" encoding="utf-8"/>

<!-- Author: Kent Finley -->
<!-- Purpose: Convert MusicXML file as exported by iReal Pro to JSON format required by SessionBand Jazz Volume 1 -->
<!-- Internet Explorer can act as an XSLT processor - insert reference to this stylesheet (transform) into extracted MusicXML file -->
<!-- e.g. 
     <?xml-stylesheet type="text/xsl" href="file://C:\Users\username\Desktop\musicxml2sessionbandjazz.xsl"?>
	    can omit the path and just give the filename, if files in same directory
-->	
<!-- then drag the .xml file to the current address bar in IE, save resulting text (and text ONLY) in a text file with .sbj extension -->
<!-- import .sbj file into SessionBand Jazz Volume 1 via iTunes -->

<!-- NOT suitable for converting files with multiple time signatures, files with more than one note per harmony -->
<!-- only chord charts as exported by iReal Pro, basically -->
<!-- not extracting key signature from MusicXML file, as it doesn't really matter in SessionBand Jazz Volume 1 -->

<!-- assuming there will only be one 'part' to the score, and that measure number 1 will hold the time signature and divisions -->
<!-- exceptions to the above will probably NOT process correctly -->

	<variable name="divisions" select="score-partwise/part[1]/measure[1]/attributes/divisions" />
	<variable name="beats" select="score-partwise/part[1]/measure[1]/attributes/time/beats" />
	<!--  'beat-type' value (time signature denominator) won't be used, but may be helpful in distinguishing between 4 feel and 2 feel signatures
	<variable name="beat-type" select="score-partwise/part[1]/measure[1]/attributes/time/beat-type" />
	-->

    <template match="score-partwise">
		<text>{</text>
		<apply-templates select="./movement-title"/>
		<apply-templates select="identification/creator[@type='composer']"/>
		<text>"Genre":</text>
		<choose>
			<when test="($beats mod 3 = 0) and ($beats mod 2 != 0)">"Medium 3/4",</when>
			<when test="($beats mod 2 = 0)">"Medium Swing (4 feel)",</when>
			<otherwise>"Bossa Nova",</otherwise>
		</choose>
		<!-- only handling two possibilities for time, those divisible evenly by 3 but not by 2 will result in Medium 3/4 -->
		<!-- whereas those divisible evenly by 2 will result in Medium Swing (4 feel) -->
		<!-- 'odd' time signatures like 5/4, 7/8 MAY have odd results, but converting as Bossa Nova -->
		<!-- COMPLETE list for SessionBand Jazz Vol 1. 
			Ballad
			12/8
			Slow Swing (2 feel)
			Slow Swing (4 feel)
			Medium Swing (2 feel)
			Medium Swing (4 feel)
			Bossa Nova
			Shuffle
			Medium 3/4
			Afro Jazz
			Med Up Swing (2 feel)
			Med Up Swing (4 feel)
			Fast Latin
			Up Swing (2 feel)
			Up Swing (4 feel)
		-->
		<text>"TrackItems":[</text>
		<apply-templates select="part[1]/measure[1]"/>
		<text>],</text>
		<text>"PlaybackSpeed":1,</text>
		<text>"TrackComments":[</text>
		<apply-templates select="part[1]/measure[1]" mode="track_comments"/>
		<text>],</text>
		<text>"TrackMixer":</text>
		<text>[{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":true,"Solo":false}]</text>
		<text>}</text>
    </template>

    <template match="identification/creator">
		<text>"TrackAuthor":"</text>
		<apply-templates/>
		<text>",</text>
    </template>

    <template match="movement-title">
		<text>"TrackName":"</text>
		<apply-templates/>
		<text>"</text>
    </template>

    <template match="root/root-step">
		<variable name="root-alter" select="following-sibling::root-alter" />
		<text>"Key":</text>
		<!-- needs to be derived from both 'root-step' and 'root-alter' (accidental: 0=natural, 1=sharp, -1=flat) 
			(adding 12 before mod operation to account for 0-1, C-flat, i.e. B, and possible double-flats or sharps) 
			SessionBand Jazz (all volumes) C=0,Db=1,D=2,Eb=3,...B=11 -->
		<choose>
		   <when test=".='C'"><value-of select="(0+$root-alter+12) mod 12"/></when>
		   <when test=".='D'"><value-of select="(2+$root-alter+12) mod 12"/></when>
		   <when test=".='E'"><value-of select="(4+$root-alter+12) mod 12"/></when>
		   <when test=".='F'"><value-of select="(5+$root-alter+12) mod 12"/></when>
		   <when test=".='G'"><value-of select="(7+$root-alter+12) mod 12"/></when>
		   <when test=".='A'"><value-of select="(9+$root-alter+12) mod 12"/></when>
		   <when test=".='B'"><value-of select="(11+$root-alter+12) mod 12"/></when>
		   <otherwise><apply-templates/></otherwise>
		</choose>
		<text>,"BlockMixerState":</text>
		<text>[{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
		<text>{"Level":0.5,"Mute":true,"Solo":false}]</text>

    </template>

    <template match="note/duration">
		<text>"BeatCount":</text>
		<!-- needs to be derived from 'divisions' and 'duration' -->
		<value-of select=". div $divisions"/>
		<text>,</text>
    </template>

    <template match="kind">
		<variable name="halfdim" select="../degree[degree-value='5' and degree-alter='-1' and (degree-type='add' or degree-type='alter')]"/>
		<!-- this will actually be the 'result tree fragment' of the degree or degrees that match the predicate -->
		
		<text>{"KeyVariation":</text>
		<choose>
			<when test=".='major-minor'">8</when> 
			<when test="starts-with(.,'major')">0</when>    
			<when test="starts-with(.,'minor')">
				<choose>
					<when test="$halfdim">7</when>
					<otherwise>6</otherwise>
				</choose>
			</when>    
			<when test="starts-with(.,'dominant')">2</when>    
			<!--but there can be many alterations of the dominant, depending on 'degree'-->
			<when test=".='augmented'">4</when>    
			<!-- not really quite right, mapping to dom7#5#9-->
			<when test="starts-with(.,'diminished')">9</when>    
			<!-- but diminished could also be entered as m(7)b5 in iReal Pro -->
			<when test=".='half-diminished'">7</when>    
			<otherwise>0</otherwise>
			<!-- ideally to be derived from 'kind' AND 'degree' (for alterations of the basic harmonies) -->
			<!-- types in SessionBand Jazz Volume 1: 
					0=maj7(9)
					1=maj7#11  - altered
					2=7(13)
					3=7(b9) - altered
					4=7(#5#9) - altered
					5=7sus(13) 
					6=m7(9)
					7=m7(b5) i.e. half-diminished
					8=m(maj7)
					9=dim
			-->
		</choose>
		<text>,"BlockType":0,</text>
    </template>

    <template match="measure">
	
		<param name="repeat_counter">0</param>
		<param name="al_coda" select="false()"/>
		<param name="measure_number">1</param>
	
		<apply-templates select="harmony"/>
		
		<choose>
			<when test="barline/repeat[@direction='backward'] and $repeat_counter=0">
				<choose>
					<when test="preceding-sibling::measure/barline/repeat[@direction='forward']">
						<apply-templates select="preceding-sibling::measure[barline[repeat[@direction='forward']]]">
							<with-param name="repeat_counter" select="$repeat_counter+1"/>
							<with-param name="al_coda" select="$al_coda"/>
							<with-param name="measure_number" select="$measure_number + 1"/>
						</apply-templates>
					</when>
					<otherwise>
						<apply-templates select="../measure[1]">
							<with-param name="repeat_counter" select="$repeat_counter+1"/>
							<with-param name="al_coda" select="$al_coda"/>
							<with-param name="measure_number" select="$measure_number + 1"/>
						</apply-templates>
					</otherwise>
				</choose>
			</when>
			
			<when test="direction/direction-type/words='D.C. al Coda' and not($al_coda)">
				<apply-templates select="../measure[1]">
					<with-param name="repeat_counter" select="0"/>
					<with-param name="al_coda" select="true()"/>
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</when>
		
			<when test="substring(direction/direction-type/words,1,4)='D.C.' and not($al_coda)">
			<!-- not sure entirely correct, but 'overloading' $al_coda to mean any of the D.C. or D.S. instructions
			     if it's 'D.C.' but not 'al Coda' 
				 assuming that the D.C. instruction will be to take a subsequent repeat, e.g. D.C. al 3rd ending
				 and the $repeat_counter parameter will drive where it goes in the end
				 (NOT what the test above is testing, btw - it's checking that we're not already under a D.C. instruction!)
				 -->
				<apply-templates select="../measure[1]">
					<with-param name="repeat_counter" select="$repeat_counter + 1"/>
					<with-param name="al_coda" select="true()"/>
					<!-- maybe not quite, may want to track da-capo, dal-segno, and al_coda separately -->
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</when>
				
			<when test="direction/direction-type/words='D.S. al Coda' and not($al_coda)">
				<apply-templates select="preceding-sibling::measure[direction[direction-type[segno]]]">
					<with-param name="repeat_counter" select="0"/>
					<with-param name="al_coda" select="true()"/>
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</when>

			<when test="following-sibling::measure[1]/barline/ending[@type='start']">
				<apply-templates select="following-sibling::measure[barline[ending[@type='start' and @number=($repeat_counter+1)]]]">
					<with-param name="repeat_counter" select="$repeat_counter"/>
					<with-param name="al_coda" select="$al_coda"/>
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</when>
	
			<when test="direction/direction-type/coda and $al_coda and following-sibling::measure/direction/direction-type/coda">
				<apply-templates select="following-sibling::measure[direction[direction-type[coda]]]">
					<with-param name="repeat_counter" select="$repeat_counter"/>
					<with-param name="al_coda" select="true()"/>
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</when>
			
			<otherwise>
				<apply-templates select="following::measure[1]">
					<with-param name="repeat_counter" select="$repeat_counter"/>
					<with-param name="al_coda" select="$al_coda"/>
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</otherwise>
			
		</choose>
	
	</template>
	
	<template match="harmony">
	
		<!-- ideally, delay processing until we know that following measure/harmony is not the same harmony with a duration that would
		     fit within 2 measures (considering total duration accumulated so far), OR that there is no following measure-->
		<!-- hard to work into the recursion of 'measure' though, need same/repeated parameters? 
			 It was easier when we only processed harmonies as they occurred on the page, so one following the next, not necessarily as they were to be played with the instructions now incorporated-->
		<!--
		<param name="accumduration">0</param>
		-->
				 
		<variable name="curkind" select="kind"/>
		<variable name="curduration" select="following-sibling::note[1]/duration"/>
		<variable name="currootstep" select="root/root-step"/>
		<variable name="currootalter" select="root/root-alter"/>
		
		<!--
		<variable name="nextkind" select="following::harmony[1]/kind"/>
		<variable name="nextduration" select="following::harmony[1]/following-sibling::note[1]/duration"/>
		<variable name="nextrootstep" select="following::harmony[1]/root/root-step"/>
		<variable name="nextrootalter" select="following::harmony[1]/root/root-alter"/>
		-->
		
		<!-- these will actually be the 'result tree fragments' of the degree or degrees that match the predicates -->
		<!-- the fact of their having a value will be enough to treat them as a 'boolean' variable, in version 1.0 -->
		<!-- 2.0 processors may change that(?) so an explicit cast to boolean might be better -->
		<variable name="subthree" select="degree[degree-value='3' and degree-type='subtract']"/>
		<variable name="addfour" select="degree[degree-value='4' and degree-alter='0' and degree-type='add']"/>
		<variable name="sharpfour" select="degree[degree-value='4' and degree-alter='1' and (degree-type='add' or degree-type='alter')] |
		degree[degree-value='11' and degree-alter='1' and (degree-type='add' or degree-type='alter')]"/>
		<variable name="flatfive" select="degree[degree-value='5' and degree-alter='-1' and (degree-type='add' or degree-type='alter')]"/>
		<variable name="sharpfive" select="degree[degree-value='5' and degree-alter='1' and (degree-type='add' or degree-type='alter')] |
		degree[degree-value='13' and degree-alter='-1' and (degree-type='add' or degree-type='alter')]"/>
		<variable name="addseven" select="degree[degree-value='7' and degree-alter='0' and degree-type='add']"/>
		<variable name="flatnine" select="degree[degree-value='9' and degree-alter='-1' and (degree-type='add' or degree-type='alter')]"/>
		<variable name="sharpnine" select="degree[degree-value='9' and degree-alter='1' and (degree-type='add' or degree-type='alter')]"/>
					
		<variable name="keyvariation">
		<!-- types in SessionBand Jazz apps: 
				0=maj7(9)
				1=maj7#11  - altered
				2=7(13)
				3=7(b9) - altered
				4=7(#5#9) - altered
				5=7sus(13) 
				6=m7(9)
				7=m7(b5) i.e. half-diminished
				8=m(maj7)
				9=dim
		-->
			<choose>
				<when test="starts-with($curkind,'diminished')">9</when>    
				<when test="$curkind='major-minor'">8</when> 
				<!-- important to test above first, or condition 'starts-with(.,"major")'would pass -->
				<when test="$curkind='half-diminished'">7</when>    
				<when test="starts-with($curkind,'minor')">
					<choose>
						<when test="$flatfive">7</when>
						<otherwise>6</otherwise>
					</choose>
				</when>
				<when test="starts-with($curkind,'dominant')">
					<choose>
						<when test="$addfour and $subthree">5</when>
						<when test="$sharpfive or $sharpnine">4</when>
						<when test="$flatnine">3</when>
						<otherwise>2</otherwise>
					</choose>
				</when>    
				<when test="$curkind='suspended-fourth' and $addseven">5</when>
				<when test="$curkind='augmented'">4</when>    
				<!-- not really quite right, mapping to dom7#5#9, -->
				<when test="starts-with($curkind,'major')">
					<choose>
						<when test="$sharpfour">1</when>
						<otherwise>0</otherwise>
					</choose>
				</when>    
				<otherwise>0</otherwise>
			</choose>
		</variable>
		
		<variable name="keyvalue">
		<!-- needs to be derived from both 'root-step' and 'root-alter' (accidental: 0=natural, 1=sharp, -1=flat) 
					(adding 12 before mod operation to account for 0-1, C-flat, i.e. B, and possible double-flats or sharps) -->
			<choose>
			   <when test="$currootstep='C'"><value-of select="(0+$currootalter+12) mod 12"/></when>
			   <when test="$currootstep='D'"><value-of select="(2+$currootalter+12) mod 12"/></when>
			   <when test="$currootstep='E'"><value-of select="(4+$currootalter+12) mod 12"/></when>
			   <when test="$currootstep='F'"><value-of select="(5+$currootalter+12) mod 12"/></when>
			   <when test="$currootstep='G'"><value-of select="(7+$currootalter+12) mod 12"/></when>
			   <when test="$currootstep='A'"><value-of select="(9+$currootalter+12) mod 12"/></when>
			   <when test="$currootstep='B'"><value-of select="(11+$currootalter+12) mod 12"/></when>
			</choose>
		</variable>
	
	<!--
		<choose>
			<when test="not(following::harmony) or ($curkind != $nextkind) or ($currootstep != $nextrootstep) or ($currootalter != $nextrootalter) or ($accumduration + $curduration &gt;= $maxduration) or ($accumduration + $curduration + $nextduration &gt; $maxduration)">
	-->	
				<text>{"KeyVariation":</text>
				<value-of select="$keyvariation"/>
				<text>,"BlockType":0</text>
				<text>,"BeatCount":</text>
		<!--
				<choose>
					<when test="$accumduration + $curduration &gt; $maxduration">
						<value-of select="$maxduration div $divisions"/>
					</when>
					<otherwise>
						<value-of select="($accumduration + $curduration) div $divisions"/>
					</otherwise>
				</choose>
		-->
				<value-of select="$curduration div $divisions"/>
				
				<text>,"Key":</text>
				<value-of select="$keyvalue"/>
				<text>,"BlockMixerState":</text>
				<text>[{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":false,"Solo":false},</text>
				<text>{"Level":0.5,"Mute":true,"Solo":false}]}</text>
				<if test="following::harmony">
					<text>,</text>
				</if>
		<!--
				<apply-templates select="following::harmony[1]">
					<with-param name="accumduration">0</with-param>
				</apply-templates>
			</when>
			<otherwise>
				<apply-templates select="following::harmony[1]">
					 <with-param name="accumduration" select="$accumduration + $curduration"/>
				</apply-templates>
			</otherwise>
		</choose>
		-->
		
	</template>
	
	<template match="measure" mode="track_comments">
	<!-- getting multiple comments per bar, that won't work. -->
		<param name="repeat_counter">0</param>
		<param name="al_coda" select="false()"/>
		<param name="measure_number">1</param>
	
		<choose>
			<when test="direction">
				<if test="$measure_number != 1"><text>,</text></if>
				<text>{"BarIndex":</text>
				<value-of select="$measure_number - 1"/>
				<text>,"CommentKey":"</text>
				<!-- take just the 1st direction, if more than one, since comments can only be up to 10 characters -->
				<for-each select="direction[1]/direction-type/*">
					<choose>
						<when test="name()='words' or name()='rehearsal'">
							<value-of select="substring(.,1,10)"/>
						</when>
						<when test="self::*">
							<!-- if the value of the direction is itself a node, take the 1st 10 characters of the node's name -->
							<value-of select="substring(name(),1,10)"/>
						</when>
					</choose>
				</for-each>
				<text>"}</text>
			</when>
			<otherwise>
				<apply-templates mode="track_comments"/>
				<!-- this is perhaps introducing the multiple indexes of comments - is it better to have 'Section A' marked as A,
				     or the 'forward repeat' direction - can both be incorporated? perhaps with multi-pronged tests, yes -->
			</otherwise>
		</choose>
		<!-- possible there may be (multiple) directions AND repeats AND/or endings in same bar, will have to establish precedence with only 10 chars - getting multiple comments for same Measure (which is 'correct' in fact, but won't work in SBJ)-->
		<!-- collapsing it all to one 'choose', I only get the first measure's direction (rehearsal mark A in In Her Family, for instance) -->
			
		<choose>
			<when test="barline/repeat[@direction='forward'] and $repeat_counter=0">
				<if test="$measure_number != 1"><text>,</text></if>
				<text>{"BarIndex":</text>
				<value-of select="$measure_number - 1"/>
				<text>,"CommentKey":"|:"}</text>
			</when>
			
			<when test="barline/repeat[@direction='backward'] and $repeat_counter=0">
				<if test="$measure_number != 1"><text>,</text></if>
				<text>{"BarIndex":</text>
				<value-of select="$measure_number - 1"/>
				<text>,"CommentKey":":|"}</text>
				<choose>
					<when test="preceding-sibling::measure/barline/repeat[@direction='forward']">
						<apply-templates select="preceding-sibling::measure[barline[repeat[@direction='forward']]]"
										 mode="track_comments">
							<with-param name="repeat_counter" select="$repeat_counter+1"/>
							<with-param name="al_coda" select="$al_coda"/>
							<with-param name="measure_number" select="$measure_number + 1"/>
						</apply-templates>
					</when>
					<otherwise>
						<apply-templates select="../measure[1]"
										 mode="track_comments">
							<with-param name="repeat_counter" select="$repeat_counter+1"/>
							<with-param name="al_coda" select="$al_coda"/>
							<with-param name="measure_number" select="$measure_number + 1"/>
						</apply-templates>
					</otherwise>
				</choose>
			</when>
			
			<when test="direction/direction-type/words='D.C. al Coda' and not($al_coda)">
				<apply-templates select="../measure[1]"
								 mode="track_comments">
					<with-param name="repeat_counter" select="0"/>
					<!-- do we want repeat_counter = 0 here? -->
					<with-param name="al_coda" select="true()"/>
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</when>
		
			<when test="substring(direction/direction-type/words,1,4)='D.C.' and not($al_coda)">
			<!-- not sure entirely safe, but 'overloading' $al_coda to mean any of the D.C. or D.S. instructions
			     if it's 'D.C.' but not 'al Coda' (NOT what the test above is testing, btw)
				 assuming that the D.C. instruction will be to take a subsequent repeat,
				 and the $repeat_counter parameter will drive where it goes in the end -->
				<apply-templates select="../measure[1]"
								 mode="track_comments">
					<with-param name="repeat_counter" select="$repeat_counter + 1"/>
					<with-param name="al_coda" select="true()"/>
					<!-- maybe not quite, may want to track da-capo, dal-segno, and al_coda separately -->
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</when>
				
			<when test="direction/direction-type/words='D.S. al Coda' and not($al_coda)">
				<apply-templates select="preceding-sibling::measure[direction[direction-type[segno]]]"
								 mode="track_comments">
					<with-param name="repeat_counter" select="0"/>
					<with-param name="al_coda" select="true()"/>
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</when>

			<when test="following-sibling::measure[1]/barline/ending[@type='start']">
				<apply-templates select="following-sibling::measure[barline[ending[@type='start' and @number=($repeat_counter+1)]]]" 
								 mode="track_comments">
					<with-param name="repeat_counter" select="$repeat_counter"/>
					<with-param name="al_coda" select="$al_coda"/>
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</when>
	
			<when test="direction/direction-type/coda and $al_coda and following-sibling::measure/direction/direction-type/coda">
				<apply-templates select="following-sibling::measure[direction[direction-type[coda]]]" 
								 mode="track_comments">
					<with-param name="repeat_counter" select="$repeat_counter"/>
					<with-param name="al_coda" select="true()"/>
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</when>
			
			<otherwise>
				<apply-templates select="following::measure[1]" 
								 mode="track_comments">
					<with-param name="repeat_counter" select="$repeat_counter"/>
					<with-param name="al_coda" select="$al_coda"/>
					<with-param name="measure_number" select="$measure_number + 1"/>
				</apply-templates>
			</otherwise>

		</choose>
		
	</template>
	
	<template match="node() | @*" mode="track_comments">
		<!-- suppress anything not explicitly handled above for track_comments mode-->
	</template>

</transform>