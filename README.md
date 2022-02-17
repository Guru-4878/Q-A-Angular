# Q-A-Angular


1.What is angular?
	angular is opensource based type script frame work. it makes easy to build devlop fornt end application mobile/Desktop/Phones.
	the main features of anguar is declarative templates, dependency injection, end to end tooling.
2.What is TypeScript?
   TypeScript is a super set of javascripts created by microsoft.here types and classes,async/wait other features will converted into plan javascripts.
3.What are the key components of Angular?
	1.Components : Component controls the html view
	2.Services   : shared the data to the entire pplication
	3.Modules	 : madules is maintain pice of code for all Directives,components..etc
	4.Templates	 : templates is view the content to show user
	5.Metadata   :	
4.What are directives?
	Directives add behaviour of existing of DOM Element or existing component instance
	Exmaple And Usage:
	import { Directive, ElementRef, Input } from '@angular/core';
	
	@Directive({ selector: '[myHighlight]' })
	export class HighlightDirective {
		constructor(el: ElementRef) {
		el.nativeElement.style.backgroundColor = 'yellow';
		}
	}
	<p myHighlight>Highlight me!</p>
	
