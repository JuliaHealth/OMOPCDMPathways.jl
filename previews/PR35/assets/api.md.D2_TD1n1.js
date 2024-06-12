import{_ as a,c as s,o as n,a6 as e}from"./chunks/framework.BBRSGyax.js";const b=JSON.parse('{"title":"API","description":"","frontmatter":{},"headers":[],"relativePath":"api.md","filePath":"api.md","lastUpdated":null}'),t={name:"api.md"},p=e(`<h1 id="API" tabindex="-1">API <a class="header-anchor" href="#API" aria-label="Permalink to &quot;API {#API}&quot;">​</a></h1><p>This is a list of documentation associated with every single <strong>exported</strong> function from <code>OMOPCDMPathways</code>. There are a few different sections with a brief explanation of what these sections are followed by relevant functions.</p><h2 id="Pre-Processing" tabindex="-1">Pre-Processing <a class="header-anchor" href="#Pre-Processing" aria-label="Permalink to &quot;Pre-Processing {#Pre-Processing}&quot;">​</a></h2><p>This family of functions are dedicated to pre-process the Data.</p><div style="border-width:1px;border-style:solid;border-color:black;padding:1em;border-radius:25px;"><a id="OMOPCDMPathways.Period_prior_to_index" href="#OMOPCDMPathways.Period_prior_to_index">#</a> <b><u>OMOPCDMPathways.Period_prior_to_index</u></b> — <i>Function</i>. <p>function Period_prior_to_index(cohort_id::Vector, conn; date_prior=Day(100), tab=cohort)</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Given a vector of cohort IDs, this function returna a DataFrame with the cohort_start_date adjusted by the date_prior.</span></span>
<span class="line"><span></span></span>
<span class="line"><span># Arguments:</span></span>
<span class="line"><span></span></span>
<span class="line"><span>- \`cohort_id\` - vector of cohort IDs</span></span>
<span class="line"><span>- \`conn\` - database connection</span></span>
<span class="line"><span></span></span>
<span class="line"><span># Keyword Arguments:</span></span>
<span class="line"><span></span></span>
<span class="line"><span>- \`date_prior\` - period prior to the index date; default is 100 days</span></span>
<span class="line"><span>- \`tab\` - the \`SQLTable\` representing the cohort table; default \`cohort\`</span></span>
<span class="line"><span></span></span>
<span class="line"><span># Returns</span></span>
<span class="line"><span></span></span>
<span class="line"><span>- DataFrame with the cohort_start_date adjusted by the date_prior.</span></span></code></pre></div><p><a href="https://github.com/JuliaHealth/OMOPCDMPathways.jl/blob/607a62e5647c591aa213619978a34552716e7d51/src/preprocessing.jl#L63-L81" target="_blank" rel="noreferrer">source</a></p><p>function Period_prior_to_index(person_ids::Vector, start_date_on_person::Function, conn; date_prior=Day(100))</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Given a vector of person IDs, this function returns a DataFrame with the cohort_start_date adjusted by the date_prior.</span></span>
<span class="line"><span></span></span>
<span class="line"><span># Arguments:</span></span>
<span class="line"><span></span></span>
<span class="line"><span>- \`person_ids\` - vector of person IDs</span></span>
<span class="line"><span>- \`start_date_on_person\` - function that returns the SQL query to get the start date of the person</span></span>
<span class="line"><span>- \`conn\` - database connection</span></span>
<span class="line"><span></span></span>
<span class="line"><span># Keyword Arguments:</span></span>
<span class="line"><span></span></span>
<span class="line"><span>- \`date_prior\` - period prior to the index date; default is 100 days</span></span>
<span class="line"><span></span></span>
<span class="line"><span># Returns</span></span>
<span class="line"><span></span></span>
<span class="line"><span>- DataFrame with the cohort_start_date adjusted by the date_prior.</span></span></code></pre></div><p><a href="https://github.com/JuliaHealth/OMOPCDMPathways.jl/blob/607a62e5647c591aa213619978a34552716e7d51/src/preprocessing.jl#L104-L122" target="_blank" rel="noreferrer">source</a></p></div><br>`,6),r=[p];function o(i,c,l,d,h,_){return n(),s("div",null,r)}const f=a(t,[["render",o]]);export{b as __pageData,f as default};
