<!DOCTYPE html>
<!-- saved from url=(0077)https://www.gnu.org/software/emacs/manual/html_node/elisp/List-Variables.html -->
<html><!-- Created by GNU Texinfo 7.0.3, https://www.gnu.org/software/texinfo/ --><head><meta http-equiv="Content-Type" content="text/html; charset=UTF-8">

<title>List Variables (GNU Emacs Lisp Reference Manual)</title>

<meta name="description" content="List Variables (GNU Emacs Lisp Reference Manual)">
<meta name="keywords" content="List Variables (GNU Emacs Lisp Reference Manual)">
<meta name="resource-type" content="document">
<meta name="distribution" content="global">
<meta name="Generator" content="makeinfo">
<meta name="viewport" content="width=device-width,initial-scale=1">

<link rev="made" href="mailto:bug-gnu-emacs@gnu.org">
<link rel="icon" type="image/png" href="https://www.gnu.org/graphics/gnu-head-mini.png">
<meta name="ICBM" content="42.256233,-71.006581">
<meta name="DC.title" content="gnu.org">
<style type="text/css">
@import url('/software/emacs/manual.css');
</style>
</head>

<body lang="en">
<div class="section-level-extent" id="List-Variables">
<div class="nav-panel">
<p>
Next: <a href="https://www.gnu.org/software/emacs/manual/html_node/elisp/Modifying-Lists.html" accesskey="n" rel="next">Modifying Existing List Structure</a>, Previous: <a href="https://www.gnu.org/software/emacs/manual/html_node/elisp/Building-Lists.html" accesskey="p" rel="prev">Building Cons Cells and Lists</a>, Up: <a href="https://www.gnu.org/software/emacs/manual/html_node/elisp/Lists.html" accesskey="u" rel="up">Lists</a> &nbsp; [<a href="https://www.gnu.org/software/emacs/manual/html_node/elisp/index.html#SEC_Contents" title="Table of contents" rel="contents">Contents</a>][<a href="https://www.gnu.org/software/emacs/manual/html_node/elisp/Index.html" title="Index" rel="index">Index</a>]</p>
</div>
<hr>
<h3 class="section" id="Modifying-List-Variables">5.5 Modifying List Variables</h3>
<a class="index-entry-id" id="index-modify-a-list"></a>
<a class="index-entry-id" id="index-list-modification"></a>

<p>These functions, and one macro, provide convenient ways
to modify a list which is stored in a variable.
</p>
<dl class="first-deffn first-defmac-alias-first-deffn">
<dt class="deffn defmac-alias-deffn" id="index-push"><span class="category-def">Macro: </span><span><strong class="def-name">push</strong> <var class="def-var-arguments">element listname</var><a class="copiable-link" href="https://www.gnu.org/software/emacs/manual/html_node/elisp/List-Variables.html#index-push"> ¶</a></span></dt>
<dd><p>This macro creates a new list whose <small class="sc">CAR</small> is <var class="var">element</var> and
whose <small class="sc">CDR</small> is the list specified by <var class="var">listname</var>, and saves that
list in <var class="var">listname</var>.  In the simplest case, <var class="var">listname</var> is an
unquoted symbol naming a list, and this macro is equivalent
to <code class="code">(setq&nbsp;<var class="var">listname</var>&nbsp;(cons&nbsp;<var class="var">element</var>&nbsp;<var class="var">listname</var>))</code><!-- /@w -->.
</p>
<div class="example">
<pre class="example-preformatted">(setq l '(a b))
     ⇒ (a b)
(push 'c l)
     ⇒ (c a b)
l
     ⇒ (c a b)
</pre></div>

<p>More generally, <code class="code">listname</code> can be a generalized variable.  In
that case, this macro does the equivalent of <code class="code">(setf&nbsp;<var class="var">listname</var>&nbsp;(cons&nbsp;<var class="var">element</var>&nbsp;<var class="var">listname</var>))</code><!-- /@w -->.
See <a class="xref" href="https://www.gnu.org/software/emacs/manual/html_node/elisp/Generalized-Variables.html">Generalized Variables</a>.
</p>
<p>For the <code class="code">pop</code> macro, which removes the first element from a list,
See <a class="xref" href="https://www.gnu.org/software/emacs/manual/html_node/elisp/List-Elements.html">Accessing Elements of Lists</a>.
</p></dd></dl>

<p>Two functions modify lists that are the values of variables.
</p>
<dl class="first-deffn first-defun-alias-first-deffn">
<dt class="deffn defun-alias-deffn" id="index-add_002dto_002dlist"><span class="category-def">Function: </span><span><strong class="def-name">add-to-list</strong> <var class="def-var-arguments">symbol element &amp;optional append compare-fn</var><a class="copiable-link" href="https://www.gnu.org/software/emacs/manual/html_node/elisp/List-Variables.html#index-add_002dto_002dlist"> ¶</a></span></dt>
<dd><p>This function sets the variable <var class="var">symbol</var> by consing <var class="var">element</var>
onto the old value, if <var class="var">element</var> is not already a member of that
value.  It returns the resulting list, whether updated or not.  The
value of <var class="var">symbol</var> had better be a list already before the call.
<code class="code">add-to-list</code> uses <var class="var">compare-fn</var> to compare <var class="var">element</var>
against existing list members; if <var class="var">compare-fn</var> is <code class="code">nil</code>, it
uses <code class="code">equal</code>.
</p>
<p>Normally, if <var class="var">element</var> is added, it is added to the front of
<var class="var">symbol</var>, but if the optional argument <var class="var">append</var> is
non-<code class="code">nil</code>, it is added at the end.
</p>
<p>The argument <var class="var">symbol</var> is not implicitly quoted; <code class="code">add-to-list</code>
is an ordinary function, like <code class="code">set</code> and unlike <code class="code">setq</code>.  Quote
the argument yourself if that is what you want.
</p>
<p>Do not use this function when <var class="var">symbol</var> refers to a lexical
variable.
</p></dd></dl>

<p>Here’s a scenario showing how to use <code class="code">add-to-list</code>:
</p>
<div class="example">
<pre class="example-preformatted">(setq foo '(a b))
     ⇒ (a b)

(add-to-list 'foo 'c)     ;; <span class="r">Add <code class="code">c</code>.</span>
     ⇒ (c a b)

(add-to-list 'foo 'b)     ;; <span class="r">No effect.</span>
     ⇒ (c a b)

foo                       ;; <span class="r"><code class="code">foo</code> was changed.</span>
     ⇒ (c a b)
</pre></div>

<p>An equivalent expression for <code class="code">(add-to-list '<var class="var">var</var>
<var class="var">value</var>)</code> is this:
</p>
<div class="example">
<pre class="example-preformatted">(if (member <var class="var">value</var> <var class="var">var</var>)
    <var class="var">var</var>
  (setq <var class="var">var</var> (cons <var class="var">value</var> <var class="var">var</var>)))
</pre></div>

<dl class="first-deffn first-defun-alias-first-deffn">
<dt class="deffn defun-alias-deffn" id="index-add_002dto_002dordered_002dlist"><span class="category-def">Function: </span><span><strong class="def-name">add-to-ordered-list</strong> <var class="def-var-arguments">symbol element &amp;optional order</var><a class="copiable-link" href="https://www.gnu.org/software/emacs/manual/html_node/elisp/List-Variables.html#index-add_002dto_002dordered_002dlist"> ¶</a></span></dt>
<dd><p>This function sets the variable <var class="var">symbol</var> by inserting
<var class="var">element</var> into the old value, which must be a list, at the
position specified by <var class="var">order</var>.  If <var class="var">element</var> is already a
member of the list, its position in the list is adjusted according
to <var class="var">order</var>.  Membership is tested using <code class="code">eq</code>.
This function returns the resulting list, whether updated or not.
</p>
<p>The <var class="var">order</var> is typically a number (integer or float), and the
elements of the list are sorted in non-decreasing numerical order.
</p>
<p><var class="var">order</var> may also be omitted or <code class="code">nil</code>.  Then the numeric order
of <var class="var">element</var> stays unchanged if it already has one; otherwise,
<var class="var">element</var> has no numeric order.  Elements without a numeric list
order are placed at the end of the list, in no particular order.
</p>
<p>Any other value for <var class="var">order</var> removes the numeric order of <var class="var">element</var>
if it already has one; otherwise, it is equivalent to <code class="code">nil</code>.
</p>
<p>The argument <var class="var">symbol</var> is not implicitly quoted;
<code class="code">add-to-ordered-list</code> is an ordinary function, like <code class="code">set</code>
and unlike <code class="code">setq</code>.  Quote the argument yourself if necessary.
</p>
<p>The ordering information is stored in a hash table on <var class="var">symbol</var>’s
<code class="code">list-order</code> property.
<var class="var">symbol</var> cannot refer to a lexical variable.
</p></dd></dl>

<p>Here’s a scenario showing how to use <code class="code">add-to-ordered-list</code>:
</p>
<div class="example">
<pre class="example-preformatted">(setq foo '())
     ⇒ nil

(add-to-ordered-list 'foo 'a 1)     ;; <span class="r">Add <code class="code">a</code>.</span>
     ⇒ (a)

(add-to-ordered-list 'foo 'c 3)     ;; <span class="r">Add <code class="code">c</code>.</span>
     ⇒ (a c)

(add-to-ordered-list 'foo 'b 2)     ;; <span class="r">Add <code class="code">b</code>.</span>
     ⇒ (a b c)

(add-to-ordered-list 'foo 'b 4)     ;; <span class="r">Move <code class="code">b</code>.</span>
     ⇒ (a c b)

(add-to-ordered-list 'foo 'd)       ;; <span class="r">Append <code class="code">d</code>.</span>
     ⇒ (a c b d)

(add-to-ordered-list 'foo 'e)       ;; <span class="r">Add <code class="code">e</code></span>.
     ⇒ (a c b e d)

foo                       ;; <span class="r"><code class="code">foo</code> was changed.</span>
     ⇒ (a c b e d)
</pre></div>

</div>
<hr>
<div class="nav-panel">
<p>
Next: <a href="https://www.gnu.org/software/emacs/manual/html_node/elisp/Modifying-Lists.html">Modifying Existing List Structure</a>, Previous: <a href="https://www.gnu.org/software/emacs/manual/html_node/elisp/Building-Lists.html">Building Cons Cells and Lists</a>, Up: <a href="https://www.gnu.org/software/emacs/manual/html_node/elisp/Lists.html">Lists</a> &nbsp; [<a href="https://www.gnu.org/software/emacs/manual/html_node/elisp/index.html#SEC_Contents" title="Table of contents" rel="contents">Contents</a>][<a href="https://www.gnu.org/software/emacs/manual/html_node/elisp/Index.html" title="Index" rel="index">Index</a>]</p>
</div>





</body></html>