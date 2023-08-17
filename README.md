
<!-- saved from url=(0079)https://ftp.gnu.org/old-gnu/Manuals/elisp-manual-21-2.8/html_node/elisp_84.html -->
<html><!-- Created on May 2, 2002 by texi2html 1.64 --><!-- 
Written by: Lionel Cons <Lionel.Cons@cern.ch> (original author)
            Karl Berry  <karl@freefriends.org>
            Olaf Bachmann <obachman@mathematik.uni-kl.de>
            and many others.
Maintained by: Olaf Bachmann <obachman@mathematik.uni-kl.de>
Send bugs and suggestions to <texi2html@mathematik.uni-kl.de>
 
--><head><meta http-equiv="Content-Type" content="text/html; charset=windows-1252">
<title>GNU Emacs Lisp Reference Manual: Modifying Lists</title>

<meta name="description" content="GNU Emacs Lisp Reference Manual: Modifying Lists">
<meta name="keywords" content="GNU Emacs Lisp Reference Manual: Modifying Lists">
<meta name="resource-type" content="document">
<meta name="distribution" content="global">
<meta name="Generator" content="texi2html 1.64">

</head>

<body lang="EN" bgcolor="#FFFFFF" text="#000000" link="#0000FF" vlink="#800080" alink="#FF0000">

<a name="SEC84"></a>
<table cellpadding="1" cellspacing="1" border="0">
<tbody><tr><td valign="MIDDLE" align="LEFT">[<a href="https://ftp.gnu.org/old-gnu/Manuals/elisp-manual-21-2.8/html_node/elisp_83.html#SEC83"> &lt; </a>]</td>
<td valign="MIDDLE" align="LEFT">[<a href="https://ftp.gnu.org/old-gnu/Manuals/elisp-manual-21-2.8/html_node/elisp_85.html#SEC85"> &gt; </a>]</td>
<td valign="MIDDLE" align="LEFT"> &nbsp; </td><td valign="MIDDLE" align="LEFT">[ &lt;&lt; ]</td>
<td valign="MIDDLE" align="LEFT">[<a href="https://ftp.gnu.org/old-gnu/Manuals/elisp-manual-21-2.8/html_node/elisp.html#SEC_Top"> Up </a>]</td>
<td valign="MIDDLE" align="LEFT">[ &gt;&gt; ]</td>
<td valign="MIDDLE" align="LEFT"> &nbsp; </td><td valign="MIDDLE" align="LEFT"> &nbsp; </td><td valign="MIDDLE" align="LEFT"> &nbsp; </td><td valign="MIDDLE" align="LEFT"> &nbsp; </td><td valign="MIDDLE" align="LEFT">[<a href="https://ftp.gnu.org/old-gnu/Manuals/elisp-manual-21-2.8/html_node/elisp.html#SEC_Top">Top</a>]</td>
<td valign="MIDDLE" align="LEFT">[<a href="https://ftp.gnu.org/old-gnu/Manuals/elisp-manual-21-2.8/html_node/elisp_toc.html#SEC_Contents">Contents</a>]</td>
<td valign="MIDDLE" align="LEFT">[<a href="https://ftp.gnu.org/old-gnu/Manuals/elisp-manual-21-2.8/html_node/elisp_728.html#SEC728">Index</a>]</td>
<td valign="MIDDLE" align="LEFT">[<a href="https://ftp.gnu.org/old-gnu/Manuals/elisp-manual-21-2.8/html_node/elisp_abt.html#SEC_About"> ? </a>]</td>
</tr></tbody></table>
<hr size="1">
<h2> 5.6 Modifying Existing List Structure </h2>
<!--docid::SEC84::-->
<p>

  You can modify the CAR and CDR contents of a cons cell with the
primitives <code>setcar</code> and <code>setcdr</code>.  We call these "destructive" 
operations because they change existing list structure.
</p><p>

<a name="IDX231"></a>
</p><blockquote>
<a name="IDX232"></a>
<a name="IDX233"></a>
<b>Common Lisp note:</b> Common Lisp uses functions <code>rplaca</code> and
<code>rplacd</code> to alter list structure; they change structure the same
way as <code>setcar</code> and <code>setcdr</code>, but the Common Lisp functions
return the cons cell while <code>setcar</code> and <code>setcdr</code> return the
new CAR or CDR.
</blockquote>
<p>

</p><blockquote><table border="0" cellspacing="0"> 
<tbody><tr><td align="left" valign="TOP"><a href="https://ftp.gnu.org/old-gnu/Manuals/elisp-manual-21-2.8/html_node/elisp_85.html#SEC85">5.6.1 Altering List Elements with <code>setcar</code></a></td><td>&nbsp;&nbsp;</td><td align="left" valign="TOP">Replacing an element in a list.</td></tr>
<tr><td align="left" valign="TOP"><a href="https://ftp.gnu.org/old-gnu/Manuals/elisp-manual-21-2.8/html_node/elisp_86.html#SEC86">5.6.2 Altering the CDR of a List</a></td><td>&nbsp;&nbsp;</td><td align="left" valign="TOP">Replacing part of the list backbone.
                      This can be used to remove or add elements.</td></tr>
<tr><td align="left" valign="TOP"><a href="https://ftp.gnu.org/old-gnu/Manuals/elisp-manual-21-2.8/html_node/elisp_87.html#SEC87">5.6.3 Functions that Rearrange Lists</a></td><td>&nbsp;&nbsp;</td><td align="left" valign="TOP">Reordering the elements in a list; combining lists.</td></tr>
</tbody></table></blockquote>
<p>

<a name="Setcar"></a>
</p><hr size="1">
<br>  
<font size="-1">
This document was generated
on <i>May 2, 2002</i>
using <a href="http://www.mathematik.uni-kl.de/~obachman/Texi2html"><i>texi2html</i></a>



</font></body></html>