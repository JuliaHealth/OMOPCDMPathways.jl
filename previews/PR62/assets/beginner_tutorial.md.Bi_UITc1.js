import{_ as a,c as i,o as s,a7 as e}from"./chunks/framework.Dq6kGRM7.js";const E=JSON.parse('{"title":"Beginner Tutorial 🐣","description":"","frontmatter":{},"headers":[],"relativePath":"beginner_tutorial.md","filePath":"beginner_tutorial.md","lastUpdated":null}'),t={name:"beginner_tutorial.md"},n=e(`<h1 id="Beginner-Tutorial" tabindex="-1">Beginner Tutorial 🐣 <a class="header-anchor" href="#Beginner-Tutorial" aria-label="Permalink to &quot;Beginner Tutorial 🐣 {#Beginner-Tutorial}&quot;">​</a></h1><p>This tutorial will guide you through the basics of using the OMOP CDM Pathways package. And will guide how one can build full Pathways followed by the patient.</p><p>The tutorial will cover the following topics:</p><ol><li><p><a href="/OMOPCDMPathways.jl/previews/PR62/beginner_tutorial#Installation-&amp;-Environment-Setup">Installation &amp; Environment Setup</a></p></li><li><p><a href="/OMOPCDMPathways.jl/previews/PR62/beginner_tutorial#Packages">Packages</a></p></li><li><p><a href="/OMOPCDMPathways.jl/previews/PR62/beginner_tutorial#Getting-the-Data-Ready">Getting the Data Ready</a></p></li><li><p><a href="/OMOPCDMPathways.jl/previews/PR62/beginner_tutorial#Building-Pathways">Building Pathways</a></p></li><li><p><a href="/OMOPCDMPathways.jl/previews/PR62/beginner_tutorial#Visualizing-Pathways">Visualizing Pathways</a></p></li><li><p><a href="/OMOPCDMPathways.jl/previews/PR62/beginner_tutorial#Pathway-Analysis">Pathway Analysis</a></p></li></ol><h2 id="Environment-Set-Up" tabindex="-1">Environment Set-Up 📝 <a class="header-anchor" href="#Environment-Set-Up" aria-label="Permalink to &quot;Environment Set-Up 📝 {#Environment-Set-Up}&quot;">​</a></h2><p>For this tutorial, you will need to activate an environment; to get into package mode within your Julia REPL, write <code>]</code>:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">pkg</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> activate TUTORIAL</span></span></code></pre></div><h3 id="Packages" tabindex="-1">Packages <a class="header-anchor" href="#Packages" aria-label="Permalink to &quot;Packages {#Packages}&quot;">​</a></h3><p>You will need the following packages for this tutorial which you can install in package mode:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">TUTORIAL</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> add OMOPCDMPathways</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">TUTORIAL</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> add OMOPCDMCohortCreator</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">TUTORIAL</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> add SQLite</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">TUTORIAL</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> add DataFrames</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">TURORIAL</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> add HealthSampleData</span></span></code></pre></div><p>To learn more about these packages, see the <a href="/OMOPCDMPathways.jl/previews/PR62/beginner_tutorial#appendix">Appendix</a>.</p><h3 id="Getting-the-Data-Ready" tabindex="-1">Getting the Data Ready <a class="header-anchor" href="#Getting-the-Data-Ready" aria-label="Permalink to &quot;Getting the Data Ready {#Getting-the-Data-Ready}&quot;">​</a></h3><p>For this tutorial, we will work with data from <a href="https://github.com/OHDSI/Eunomia" target="_blank" rel="noreferrer">Eunomia</a> that is stored in a SQLite format. To install the data on your machine, execute the following code block and follow the prompts - you will need a stable internet connection for the download to complete:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">import</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> HealthSampleData</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Eunomia</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">eunomia </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Eunomia</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span></code></pre></div><h2 id="Connecting-to-the-Eunomia-Database" tabindex="-1">Connecting to the Eunomia Database 💾 <a class="header-anchor" href="#Connecting-to-the-Eunomia-Database" aria-label="Permalink to &quot;Connecting to the Eunomia Database 💾 {#Connecting-to-the-Eunomia-Database}&quot;">​</a></h2><p>After you have finished your set up in the Julia, we need to establish a connection to the Eunomia SQLite database that we will use for the rest of the tutorial:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">import</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> SQLite</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DB</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">conn </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> DB</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(eunomia)</span></span></code></pre></div><p>With Eunomia, the database&#39;s schema is simply called &quot;main&quot;. We will use this to generate database connection details that will inform <code>OMOPCDMCohortCreator</code> about the type of queries we will write (i.e. SQLite) and the name of the database&#39;s schema. For this step, we will use <code>OMOPCDMCohortCreator</code>:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">import</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> OMOPCDMCohortCreator </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">as</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> occ</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">occ</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">GenerateDatabaseDetails</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    :sqlite</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">    &quot;main&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Finally, we will generate internal representations of each table found within Eunomia for OMOPCDMCohortCreator to use:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">occ</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">GenerateTables</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(conn)</span></span></code></pre></div><p>As a check to make sure everything was correctly installed and works properly, the following block should work and return a list of all person ids in this data:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">occ</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">GetDatabasePersonIDs</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(conn)</span></span></code></pre></div><h2 id="Building-Pathways" tabindex="-1">Building Pathways 🚀 <a class="header-anchor" href="#Building-Pathways" aria-label="Permalink to &quot;Building Pathways 🚀 {#Building-Pathways}&quot;">​</a></h2><p>The very first step is to do perform the Data-Preprocessing and then we can start building the Pathways.</p><p>(1) The first pre-processing is to get the Data filtered cum sorted based on the index start date by a thresold of <code>periodPriorToIndex</code> days.</p><p>So, let&#39;s say we have the patient <code>cohort_id</code>:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">cohort_id </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> [</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span></span></code></pre></div><p>Then to apply the Data-Preprocessing, we can do something like this:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">date_prior </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Day</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">100</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">period_prior_to_index</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(cohort_id,  conn,   date_prior)</span></span></code></pre></div><p>Given cohort_id&#39;s , this would return a DataFrame with the cohort_start_date adjusted to prior each subjects&#39; cohort entry date.</p><p>(2) The next thing to consider is that in a medical setting, If an individual receives the same treatment for a longer period of time (e.g. need of chronic treatment), one is likely to need reﬁlls. As patients are not 100% adherent, there might be a gap between two subsequent event eras. Usually, these eras are still considered as one treatment episode and the eraCollapseSize deﬁnes the maximum gap within which two eras of the same event cohort would be collapsed into one era (i.e. seen as continuous treatment instead of a stop and re-initiation of the same treatment).</p><p>And this can be handeled by Collapsing treatment eras if the gap between them is smaller than a specific threshold.</p><p>This can be done using the <code>EraCollapse</code> function by doing something like this:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">eraCollapseSize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Day</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">30</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">EraCollapse</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(treatment_history, eraCollapseSize)</span></span></code></pre></div><p>(3) Further, the issue we might see is that the duration of extracted event eras may vary a lot so it is preferable to limit to only treatments exceeding a minimum duration. Hence minEraDuration speciﬁes the minimum time an event era should last to be included in the analysis.</p><p>This can be done using the <code>calculate_era_duration</code> function by doing like this:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">minEraDuration </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Day</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">30</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">calculate_era_duration</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(treatment_history, minEraDuration)</span></span></code></pre></div>`,38),l=[n];function h(p,o,r,d,k,c){return s(),i("div",null,l)}const u=a(t,[["render",h]]);export{E as __pageData,u as default};
