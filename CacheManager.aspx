﻿<%@ Page Language="C#" AutoEventWireup="true" %>

<%@ Import Namespace="Sitecore.Sites"%>
<%@ Import Namespace="Sitecore.Caching"%>
<%@ Import Namespace="Sitecore.Configuration"%>
<%@ Import Namespace="Sitecore.Diagnostics"%>
<%@ Import Namespace="Sitecore.sitecore.admin"%>
<%@ Import Namespace="Sitecore.Abstractions"%>
<%@ Import Namespace="System"%>
<%@ Import Namespace="System.Collections"%>
<%@ Import Namespace="System.Collections.Generic"%>
<%@ Import Namespace="System.Linq"%>
<%@ Import Namespace="System.Web.UI.WebControls"%>


<script runat="server">
    #region Admin Page 

    private bool IsDeveloper {
        get {
            if (!this.User.IsInRole("sitecore\\developer"))
                return this.User.IsInRole("sitecore\\sitecore client developing");
            else
                return true;
        }
    }

    protected void CheckSecurity() {
        this.CheckSecurity(false);
    }

    protected void CheckSecurity(bool isDeveloperAllowed) {
        if (Sitecore.Context.User.IsAdministrator || isDeveloperAllowed && this.IsDeveloper)
            return;
        SiteContext site = Sitecore.Context.Site;
        if (site == null)
            return;
        this.Response.Redirect(string.Format("{0}?returnUrl={1}", (object)site.LoginPage, (object)HttpUtility.UrlEncode(this.Request.Url.PathAndQuery)));
    }

    #endregion Admin Page 

    #region Page Events

    protected override void OnInit(EventArgs arguments) {
        Assert.ArgumentNotNull((object)arguments, "arguments");
        this.CheckSecurity(true);
        base.OnInit(arguments);
    }

    //Page Load Events
    private void Page_Load(object sender, EventArgs e) {

        if (IsPostBack)
            return;

        //system site names
        List<string> SystemSiteNames = new List<string>() { "admin", "login", "modules_shell", "modules_website", "publisher", "scheduler", "service", "shell", "system", "website" };
        SetupChecklist(cblSysSiteNames, SystemSiteNames);
        //site names
        SetupChecklist(cblSiteNames, SiteContextFactory.GetSiteNames().ToList());
        //site types
        SetupChecklist(cblSiteTypes, new List<string>() { "[filtered items]", "[html]", "[partial html]", "[registry]", "[viewstate]", "[xsl]","[renderingParameters]" });
        //db types			
        SetupChecklist(cblDBTypes, new List<string>() { "[blobIDs]", "[data]", "[items]", "[itempaths]", "[paths]", "[standardValues]","[languageFallback]","[languageFallbackObsolete]","[isLanguageFallbackValid]", "[isLanguageFallbackValidObsolete]" });
        //db names
        SetupChecklist(cblDBNames, new List<string>() { "core", "filesystem", "master", "web" });
        //access result names 
        SetupChecklist(cblAccessResult, new List<string>() { "AccessResultCache" });
        //data provider names 
        SetupChecklist(cblProviderResult, new List<string>() { "SqlDataProvider - Prefetch data(core)", "SqlDataProvider - Prefetch data(master)", "SqlDataProvider - Prefetch data(web)", "PropertyStore - Property data(core)","PropertyStore - Property data(master)", "PropertyStore - Property data(web)" });
        //misc names without random types
        var miscCaches = new List<string>();
        foreach(var c in CacheManager.GetAllCaches())
        {
            if (c.Name.EndsWith("[filtered items]") || c.Name.EndsWith("[html]") || c.Name.EndsWith("[partial html]") || c.Name.EndsWith("[registry]") || c.Name.EndsWith("[viewstate]") || c.Name.EndsWith("[xsl]"))
            {
                continue;
            }
            if (c.Name.EndsWith("[blobIDs]") || c.Name.EndsWith("[data]") || c.Name.EndsWith("[items]") || c.Name.EndsWith("[itempaths]") || c.Name.EndsWith("[paths]") || c.Name.EndsWith("[standardValues]") || c.Name.EndsWith("[isLanguageFallbackValid]") || c.Name.EndsWith("[languageFallback]") || c.Name.EndsWith("[languageFallbackObsolete]") || c.Name.EndsWith("[isLanguageFallbackValidObsolete]") )
            {
                continue;
            }
            if (c.Name == "AccessResultCache")
            {
                continue;
            }
            if (c.Name.StartsWith("SqlDataProvider - Prefetch data") || c.Name.StartsWith("PropertyStore - Property data"))
            {
                continue;
            }
            miscCaches.Add(c.Name);
        }
        SetupChecklist(cblMiscNames, miscCaches);

        UpdateTotals();
    }

    #endregion Page Events

    #region Site Cache

    protected void FetchSiteCacheProfile(object sender, EventArgs e) {

        rptSiteCacheProfiles.DataSource = GetCachesByNames(GetSelectedSiteNames(),true);
        rptSiteCacheProfiles.DataBind();
    }
    
    protected void FetchSiteCacheProfileContent(object sender, EventArgs e) {

        rptSiteCacheProfiles.DataSource = GetCachesByNames(GetSelectedSiteNames(),true,false,1);
        rptSiteCacheProfiles.DataBind();
    }
    
    protected void FetchSiteCacheProfileContentEncode(object sender, EventArgs e) {
    
            rptSiteCacheProfiles.DataSource = GetCachesByNames(GetSelectedSiteNames(),true,false,2);
            rptSiteCacheProfiles.DataBind();
    }
    
    protected void ClearSiteCacheProfile(object sender, EventArgs e) {

        List<MyCache> list = GetCachesByNames(GetSelectedSiteNames(),false,true);
        rptSiteCaches.DataSource = list;
        rptSiteCaches.DataBind();
    }

    protected void FetchSiteCacheList(object sender, EventArgs e) {

        rptSiteCaches.DataSource = GetCachesByNames(GetSelectedSiteNames(),false);
        rptSiteCaches.DataBind();
    }

    #endregion Site Cache

    #region Database

    protected void FetchDBCacheProfile(object sender, EventArgs e) {

        rptDBCacheProfiles.DataSource = GetCachesByNames(GetSelectedDBNames(), true) ;
        rptDBCacheProfiles.DataBind();
    }

    protected void ClearDBCacheProfile(object sender, EventArgs e) {

        List<MyCache> list = GetCachesByNames(GetSelectedDBNames(),false,true);
        rptDBCaches.DataSource = list;
        rptDBCaches.DataBind();
    }

    protected void FetchDBCacheList(object sender, EventArgs e) {

        rptDBCaches.DataSource = GetCachesByNames(GetSelectedDBNames(),false);
        rptDBCaches.DataBind();
    }

    #endregion Database

    #region Access Result

    protected void FetchARCacheProfile(object sender, EventArgs e) {

        rptARCacheProfiles.DataSource = GetCachesByNames(GetSelectedItemValues(cblAccessResult.Items),true);
        rptARCacheProfiles.DataBind();
    }

    protected void ClearARCacheProfile(object sender, EventArgs e) {
        rptARCaches.DataSource = GetCachesByNames(GetSelectedItemValues(cblAccessResult.Items),true,true); ;
        rptARCaches.DataBind();
    }

    protected void FetchARCacheList(object sender, EventArgs e) {
        rptARCaches.DataSource =  GetCachesByNames(GetSelectedItemValues(cblAccessResult.Items),false);
        rptARCaches.DataBind();
    }

    protected List<Sitecore.Caching.Generics.ICache<AccessResultCacheKey>> GetACCachesByNames(List<string> names) {
        var ac = Sitecore.Caching.CacheManager.GetAccessResultCache();
        List<Sitecore.Caching.Generics.ICache<AccessResultCacheKey>> returnCaches = new List<Sitecore.Caching.Generics.ICache<AccessResultCacheKey>>();
        returnCaches.Add(ac.InnerCache);
        return returnCaches;
    }
    #endregion Access Result

    #region Providers

    protected void FetchProvCacheProfile(object sender, EventArgs e) {

        rptProvCacheProfiles.DataSource = GetCachesByNames(GetSelectedItemValues(cblProviderResult.Items),true);
        rptProvCacheProfiles.DataBind();
    }

    protected void ClearProvCacheProfile(object sender, EventArgs e) {
        List<MyCache> list = GetCachesByNames(GetSelectedItemValues(cblProviderResult.Items),false,true);
        rptProvCaches.DataSource = list;
        rptProvCaches.DataBind();
    }

    protected void FetchProvCacheList(object sender, EventArgs e) {

        rptProvCaches.DataSource = GetCachesByNames(GetSelectedItemValues(cblProviderResult.Items),false);
        rptProvCaches.DataBind();
    }

    #endregion Providers

    #region Miscellaneous

    protected void FetchMiscCacheProfile(object sender, EventArgs e) {

        rptMiscCacheProfiles.DataSource = GetCachesByNames(GetSelectedItemValues(cblMiscNames.Items),true);
        rptMiscCacheProfiles.DataBind();
    }

    protected void ClearMiscCacheProfile(object sender, EventArgs e) {

        List<MyCache> list = GetCachesByNames(GetSelectedItemValues(cblMiscNames.Items),false,true);
        rptMiscCaches.DataSource = list;
        rptMiscCaches.DataBind();
    }

    protected void FetchMiscCacheList(object sender, EventArgs e) {

        rptMiscCaches.DataSource = GetCachesByNames(GetSelectedItemValues(cblMiscNames.Items),false);
        rptMiscCaches.DataBind();
    }

    #endregion Miscellaneous

    #region Global

    protected void btnGQuery_Click(object sender, EventArgs e) {
        List<ListItem> qr = new List<ListItem>();
        IEnumerable<Sitecore.Caching.ICacheInfo> allCaches = CacheManager.GetAllCaches().OrderBy(a => a.Name);

        string query = txtGQuery.Text.ToLower();
        foreach (Sitecore.Caching.ICacheInfo c in allCaches) {
            try {
                List<string> cachename = new List<string>();
                cachename.Add(c.Name);
                var cclist = GetCachesByNames(cachename,true);
                var cc = cclist[0];
                foreach (string s in cc.Keys) {
                    if (s.ToLower().Contains(query)) {
                        qr.Add(new ListItem(c.Name, s));
                    }
                }
            } catch (Exception ex) { /*some key is private and blows up*/ }
        }
        rptGQuery.DataSource = qr;
        rptGQuery.DataBind();
        ltlResults.Text = qr.Count.ToString() + " Results";
    }

    protected void btnGQueryClear_Click(object sender, EventArgs e) {
        List<ListItem> qr = new List<ListItem>();
        var allCaches = CacheManager.GetAllCaches().OrderBy(a => a.Name);

        string query = txtGQuery.Text.ToLower();
        foreach (Sitecore.Caching.ICacheInfo cInfo in allCaches) {
            try {
                ICache c = cInfo as ICache;
                foreach (string s in c.GetCacheKeys()) {
                    if (s.ToLower().Contains(query)) {
                        c.Remove(s);
                    }
                }
            } catch (Exception ex) {
                //some Key is private and blows up also some caches are not string
            }
        }
        rptGQuery.DataSource = qr;
        rptGQuery.DataBind();
        ltlResults.Text = qr.Count.ToString() + " Results";
    }

    protected void ClearAll_Click(object sender, EventArgs e) {
        foreach (Sitecore.Caching.ICacheInfo cache in CacheManager.GetAllCaches()) {
            cache.Clear();
        }
        UpdateTotals();
    }

    #endregion Global

    #region Helpers

    protected void SetupChecklist(CheckBoxList cbl, List<string> values) {
        foreach (string s in values)
            cbl.Items.Add(new ListItem(s, s));
    }

    protected void rptSCProfiles_DataBound(object sender, RepeaterItemEventArgs e) {
        Repeater rptBySite = (Repeater)e.Item.FindControl("rptBySite");
        MyCache cacheItem = (MyCache)e.Item.DataItem;
        if (rptBySite == null)
            return;
        rptBySite.DataSource = cacheItem.Keys;
        rptBySite.DataBind();
        
        Repeater rptBySite2 = (Repeater)e.Item.FindControl("rptBySite2");
	if (rptBySite2 == null)
	    return;
	rptBySite2.DataSource = cacheItem.Data;
        rptBySite2.DataBind();
    }

    protected List<string> GetSelectedSiteNames() {

        List<string> returnNames = new List<string>();

        //get selected types
        List<string> siteTypesSelected = new List<string>();
        foreach (ListItem li in cblSiteTypes.Items) {
            if (li.Selected) {
                siteTypesSelected.Add(li.Value);
            }
        }

        //get selected sites caches
        List<Sitecore.Caching.ICache> allCaches = new List<Sitecore.Caching.ICache>();
        List<string> list = GetSelectedItemValues(cblSiteNames.Items);
        list.AddRange(GetSelectedItemValues(cblSysSiteNames.Items));
        foreach (string li in list) {
            foreach (string s in siteTypesSelected) {
                returnNames.Add(li + s);
            }
        }

        return returnNames;
    }

    protected List<string> GetSelectedDBNames() {

        List<string> returnNames = new List<string>();

        //get selected types
        List<string> siteTypesSelected = new List<string>();
        foreach (ListItem li in cblDBTypes.Items) {
            if (li.Selected) {
                siteTypesSelected.Add(li.Value);
            }
        }

        //get selected sites caches
        List<Sitecore.Caching.ICache> allCaches = new List<Sitecore.Caching.ICache>();
        List<string> list = GetSelectedItemValues(cblDBNames.Items);
        foreach (string li in list) {
            foreach (string s in siteTypesSelected) {
                returnNames.Add(li + s);
            }
        }

        return returnNames;
    }

    protected List<MyCache> GetCachesByNames(List<string> names, bool includeKeys, bool clear=false, int includeContent=0) {

        List<MyCache> returnCaches = new List<MyCache>();
        foreach (string s in names) {
            MyCache c = new MyCache();
            if (s.EndsWith("[data]") || s.StartsWith("SqlDataProvider - Prefetch data"))
            {
                var dc = Sitecore.Caching.CacheManager.FindCacheByName<Sitecore.Data.ID>(s);
                if (dc != null)
                {
                    if (clear)
                    {
                        dc.Clear();
                    }
                    c.Name = dc.Name;
                    c.Size = dc.Size;
                    c.MaxSize = dc.MaxSize;
                    c.Count = dc.Count;
                    if (includeKeys)
                    {
                        c.Keys = Array.ConvertAll(dc.GetCacheKeys(), x => x.ToString());
                    }
                }
            }
            else if (s.EndsWith("[itempaths]"))
            {
                var dc = Sitecore.Caching.CacheManager.FindCacheByName<Sitecore.Caching.ItemPathCacheKey>(s);
                if (dc != null)
                {
                    if (clear)
                    {
                        dc.Clear();
                    }
                    c.Name = dc.Name;
                    c.Size = dc.Size;
                    c.MaxSize = dc.MaxSize;
                    c.Count = dc.Count;
                    if (includeKeys)
                    {
                        c.Keys = Array.ConvertAll(dc.GetCacheKeys(), x => x.ItemId.ToString());
                    }
                }
            }
            else if (s.EndsWith("[languageFallback]"))
            {
                var dc = Sitecore.Caching.CacheManager.FindCacheByName<Sitecore.Caching.LanguageFallbackFieldValuesCacheKey>(s);
                if (dc != null)
                {
                    if (clear)
                    {
                        dc.Clear();
                    }
                    c.Name = dc.Name;
                    c.Size = dc.Size;
                    c.MaxSize = dc.MaxSize;
                    c.Count = dc.Count;
                    if (includeKeys)
                    {
                        c.Keys = Array.ConvertAll(dc.GetCacheKeys(), x => x.ToString());
                    }
                }
            }
            else if (s.EndsWith("[isLanguageFallbackValid]"))
            {
                var dc = Sitecore.Caching.CacheManager.FindCacheByName<Sitecore.Caching.IsLanguageFallbackValidCacheKey>(s);
                if (dc != null)
                {
                    if (clear)
                    {
                        dc.Clear();
                    }
                    c.Name = dc.Name;
                    c.Size = dc.Size;
                    c.MaxSize = dc.MaxSize;
                    c.Count = dc.Count;
                    if (includeKeys)
                    {
                        c.Keys = Array.ConvertAll(dc.GetCacheKeys(), x => x.ToString());
                    }
                }
            }
            else if (s == "AccessResultCache")
            {
                var dc = Sitecore.Caching.CacheManager.GetAccessResultCache();
                if (dc != null)
                {
                    if (clear)
                    {
                        dc.Clear();
                    }
                    c.Name = dc.Name;
                    c.Size = dc.InnerCache.Size;
                    c.MaxSize = dc.InnerCache.MaxSize;
                    c.Count = dc.InnerCache.Count;
                    if (includeKeys)
                    {
                        c.Keys = Array.ConvertAll(dc.InnerCache.GetCacheKeys(), x => x.EntityId);
                    }
                }
            }
            else if (s == "IsUserInRoleCache")
            {
                var dc = Sitecore.Caching.CacheManager.GetIsInRoleCache();
                if (dc != null)
                {
                    if (clear)
                    {
                        dc.Clear();
                    }
                    c.Name = dc.Name;
                    c.Size = dc.InnerCache.Size;
                    c.MaxSize = dc.InnerCache.MaxSize;
                    c.Count = dc.InnerCache.Count;
                    if (includeKeys)
                    {
                        c.Keys = Array.ConvertAll(dc.InnerCache.GetCacheKeys(), x => x.ToString());
                    }
                }
            }
            else if (s == "TransformedIdentities")
            {
                var dc = Sitecore.Caching.CacheManager.FindCacheByName<Sitecore.Owin.Authentication.Caching.TransformedIdentitiesCacheKey>(s);
                if (dc != null)
                {
                    if (clear)
                    {
                        dc.Clear();
                    }
                    c.Name = dc.Name;
                    c.Size = dc.Size;
                    c.MaxSize = dc.MaxSize;
                    c.Count = dc.Count;
                    if (includeKeys)
                    {
                        c.Keys = Array.ConvertAll(dc.GetCacheKeys(), x => x.ToString());
                    }
                }
            }
            else if (s == "ExperienceAnalytics.DimensionItems" || s == "DeviceDictionaryCache" || s == "GeoIpDataDictionaryCache" || s == "LocationsDictionaryCache")
            {
                var dc = Sitecore.Caching.CacheManager.FindCacheByName<System.Guid>(s);
                if (dc != null)
                {
                    if (clear)
                    {
                        dc.Clear();
                    }
                    c.Name = dc.Name;
                    c.Size = dc.Size;
                    c.MaxSize = dc.MaxSize;
                    c.Count = dc.Count;
                    if (includeKeys)
                    {
                        c.Keys = Array.ConvertAll(dc.GetCacheKeys(), x => x.ToString());
                    }
                }
            }
            else if (s == "UserProfileCache")
            {
                var dc = Sitecore.Caching.CacheManager.FindCacheByName<Sitecore.Caching.UserProfile.UserProfileCacheKey>(s);
                if (dc != null)
                {
                    if (clear)
                    {
                        dc.Clear();
                    }
                    c.Name = dc.Name;
                    c.Size = dc.Size;
                    c.MaxSize = dc.MaxSize;
                    c.Count = dc.Count;
                    if (includeKeys)
                    {
                        c.Keys = Array.ConvertAll(dc.GetCacheKeys(), x => x.ToString());
                    }
                }
            }
            else if (s == "LAYOUT_DELTA_CACHE")
            {
                var dc = Sitecore.Caching.CacheManager.FindCacheByName<Tuple<string, IEnumerable<string>>>(s);
                if (dc != null)
                {
                    if (clear)
                    {
                        dc.Clear();
                    }
                    c.Name = dc.Name;
                    c.Size = dc.Size;
                    c.MaxSize = dc.MaxSize;
                    c.Count = dc.Count;
                    if (includeKeys)
                    {
                        c.Keys = Array.ConvertAll(dc.GetCacheKeys(), x => Server.HtmlEncode(x.Item1));
                    }
                }
            }
            else if (s == "ItemCloningRelations")
            {
                var scInfo = Sitecore.Caching.CacheManager.GetAllCaches().FirstOrDefault(x => x.Name == s);
                if (scInfo != null)
                {
                    if (clear)
                    {
                        scInfo.Clear();
                    }
                    c.Name = scInfo.Name;
                    c.Size = scInfo.Size;
                    c.MaxSize = scInfo.MaxSize;
                    c.Count = scInfo.Count;
                    if (includeKeys)
                    {
                        //not implemented due to access restriction 
                        c.Keys = new string[1] { "not implemented due to access restriction"};
                    }
                }
            }
            else
            {
                try
                {
                    var sc = Sitecore.Caching.CacheManager.FindCacheByName<string>(s);
                    if (sc != null)
                    {
                        if (clear)
                        {
                            sc.Clear();
                        }
                        c.Name = sc.Name;
                        c.Size = sc.Size;
                        c.MaxSize = sc.MaxSize;
                        c.Count = sc.Count;
                        if (includeKeys) c.Keys = sc.GetCacheKeys();
                        if (includeContent > 0) {
                        	c.Data = new Dictionary<string, string>();
                        	foreach(string key in c.Keys)
			 	{
			 		if (includeContent == 2)
			 		{
			                	c.Data.Add(key,HttpUtility.HtmlEncode(sc.GetValue(key).ToString()));
			                } else {
			                	c.Data.Add(key,sc.GetValue(key).ToString());
			                }
 		           	}
 		           	c.Keys =  null;
                        }
                    }
                } catch (Exception ex)
                {
                    //perhaps a unknow user cache or a new one.
                    var scInfo = Sitecore.Caching.CacheManager.GetAllCaches().FirstOrDefault(x => x.Name == s);
                    if (scInfo != null)
                    {
                        if (clear)
                        {
                            scInfo.Clear();
                        }
                        c.Name = scInfo.Name;
                        c.Size = scInfo.Size;
                        c.MaxSize = scInfo.MaxSize;
                        c.Count = scInfo.Count;
                        if (includeKeys)
                        {
                            //not implemented due to unknow
                            c.Keys = new string[1] { "not implemented unknown not string cache key"};
                        }
                    }
                }
            }

            if (c != null && !string.IsNullOrEmpty(c.Name)) {
                returnCaches.Add(c);
            }
        }
        return returnCaches;
    }


    protected List<string> GetSelectedItemValues(ListItemCollection lic) {
        List<string> lil = new List<string>();
        foreach (ListItem li in lic) {
            if (li.Selected) {
                lil.Add(li.Value);
            }
        }
        return lil;
    }

    protected string GetValFromB(long l) {
        long mb = 1048576;
        long kb = 1024;
        if (l > mb) {
            return (l / mb).ToString() + "MB";
        } else if (l > kb) {
            return (l / kb).ToString() + "KB";
        }
        return l.ToString() + "B";
    }

    private void UpdateTotals() {
        CacheStatistics statistics = CacheManager.GetStatistics();
        ltlEntries.Text = statistics.TotalCount.ToString();
        ltlSize.Text = GetValFromB(statistics.TotalSize);
    }

    protected string GetClass(int ItemIndex) {
        return ((ItemIndex % 2).Equals(0)) ? "even" : "odd";
    }

    public class MyCache {
        public string Name { get; set; }
        public long Count { get; set; }
        public long Size { get; set; }
        public long MaxSize { get; set; }
        public string[] Keys { get; set; }
        public Dictionary<string, string> Data { get; set; }
    }

    #endregion Helpers
</script>

<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" >
<head id="Head1" runat="server">
    <title></title>
    <style>
		.clear { clear:both; }
         * { color:#000; font-size:12px; }
		body { font-family:Arial,Helvetica,sans-serif; background-color: #f0f0f0; vertical-align: top;  }
		h1, h2, h3 { padding: 5px; margin:5px; font-style:normal; }
		h1 { color:#474747; font-size:18px; font-weight:normal; }
		h2 { background: #474747; border-bottom:1px solid #ccc; border-left:5px solid #dc291e; color: #fff; font-weight:bold; line-height: 35px; margin:0px; padding:0 0 0 15px; }
        h2.closed { background: #969696; border-bottom:1px solid #ccc; border-left:0px; padding-left:20px;}
		h3 { margin: 5px 0; }
			h3 span { font-size:12px; font-weight:normal; }
		.title { font-weight:bold; }
		.spacer { background:#fff; height: 15px; border-style:solid; border-color:#474747; border-width:0 2px; }
		.ActiveRegion,
		.Region { border-style:solid; border-color:#474747; border-width:0 2px 2px; position:relative; }
		.Region { display:none; }
		.ButtonSection { background-color:#cccccc; }
		.BtnClear { float:right; }
		.GlobalSearch, .SiteCacheList, .SiteProfileList, .DBCacheList, .DBProfileList, .ARCacheList, .ARProfileList, .MiscCacheList, .MiscProfileList { position:relative; }
		.Controls { padding:10px; }
			.fieldHighlight { border-left:4px solid #CCCCCC; padding-left:8px;}
			.dataRow { margin-bottom:5px; }
			.txtQuery { width:500px; margin-top:5px; }
			.btnSpacer { display:inline-block; line-height:16px; vertical-align:top; }
			.rowSpacer { height:15px; }
			.Controls span { display:inline-block; margin-right:20px;}
			.GlobalSearch .ButtonSection span { display:inline-block; margin-left:30px; }
		.CacheSiteForm, .CacheList, .ProfileList, .GlobalSearch { }
			.CacheSiteForm .Section { display:none;}
			.CacheSiteForm a { margin:10px 0; font-size:12px; color:#000; }
			.CacheSiteForm .Section { padding:0px 5px; background:none; } 
		.CacheList { margin-top:10px; }
			.ProfileList .Section, .CacheList .Section, .ButtonSection, .GlobalSearch .Section { padding:0px 5px 5px; background:none; display:block; }
			.ResultTitle { margin-bottom: 5px; padding: 0 5px; }
			.Results { background:#fff; border:2px groove #f0f0f0; margin-bottom: 5px; max-height: 350px; overflow: auto; padding:5px 5px 0;}
            .FormTitleRow { clear:both; }
			.FormRow { clear:both; border-bottom:1px dashed #ccc; margin-bottom:3px; padding-bottom:3px; }
			.FormRow:last-child { border-bottom:0px; }
			.RowTitle { float:left; font-weight:bold; }
				.Results .RowTitle { font-style:italic; }
			.RowValue { float:left; }
			.CacheName { width:175px; }
			.CacheKey {  }
			.Name { width: 250px }
			.Count { width: 150px }
			.Size { width: 150px }
			.MaxSize { width: 150px }
		.CacheItems { margin:0 10px 0 20px; }
		.overlay { padding-top:40px; display:none; position:absolute; top:0px; bottom:0px; right:0px; left:0px; text-align:center; background-color:#ffffff; filter:alpha(opacity=60); opacity:0.6; }
			.overlay .message { position:absolute; top:40px; width:100%; color:#333; font-size:19px; font-weight:bold; }
	    /*Sitecorey styles */
	    #EditorTabs { vertical-align: top; border-bottom:2px solid #474747; }
            #EditorTabs a { display:inline-block; white-space: nowrap; line-height: 40px; padding: 0 15px; text-decoration:none; }
            .activeTab { color: #fff; background-color:#474747; }
            .normalTab { color: #5e5e5e; background-color:#fff; }
            .btnBox { display:inline-block; height:20px; margin:5px 0; }
		        .btnMessage { float:left; padding:9px 0px 15px 5px; margin:1px; }
		        .btn { display:inline-block; margin:1px; }
                    .btn input,
		            .btn a { color:#dc291e; font-size: 8pt; border:none; background:none; float:left; height:15px; text-decoration:none; }
                    .btn input:hover,
                    .btn a:hover { text-decoration:underline; }
            .HtmlContent {border: 1px solid black;background-color: lightblue;}
	</style>
    <script src="/sitecore/shell/client/Speak/Assets/lib/ui/2.0/deps/jquery-2.1.1.min.js"></script>
    <script type="text/javascript">
    	$(document).ready(function () {
    		var allTabs = ".normalTab, .activeTab";
    		$(allTabs).click(function (e) {
    			e.preventDefault();
    			if ($(this).attr("class").indexOf("normalTab") > -1) {
    				//sort out active and normal tabs
    				$(".activeTab").removeClass("activeTab").addClass("normalTab");
    				$(this).removeClass("normalTab").addClass("activeTab");
    				//sort out prev tab
    				$(".prevTab").removeClass("prevTab");
    				var prev = $(this).prev();
    				if (prev != null)
    					$(prev).addClass("prevTab");
    				var newRegion = $(this).attr("rel");
    				$(".ActiveRegion").removeClass("ActiveRegion").addClass("Region");
    				$("." + newRegion).removeClass("Region").addClass("ActiveRegion");
    			}
    		});
    		$('h2').dblclick(function () {
    		    if ($(this).next(".Controls").is(":visible"))
    		        $(this).addClass("closed");
                else 
    		        $(this).removeClass("closed");
    			$(this).next(".Controls").toggle();
    		});
    	});
    	var IsSiteChecked = false;
    	function CheckAll(link, cssClass) {
    		var split = "";
    		var join = ""
    		if ($(link).text().indexOf("Deselect") >= 0) {
    			split = "Deselect";
    			join = "Select";
    			IsSiteChecked = false;
    		} else {
    			split = "Select";
    			join = "Deselect";
    			IsSiteChecked = true;
    		}

    		var newText = $(link).text().split(split).join(join);
    		$(link).text(newText);

    		$("." + cssClass + " input:checkbox").each(function () {
    		    $(this).prop('checked', IsSiteChecked);
    		});
    	}
    	var OverlayObject;
    	function beginRequest(sender, args) {
    		var clientId = args.get_postBackElement().id;
    		var wrapper = $("#" + clientId).attr("rel");
    		OverlayObject = $(wrapper).find(".overlay");
    		$(OverlayObject).css("display", "block");
    	}
    	function endRequest(sender, args) {
    		$(OverlayObject).css("display", "none");
    	}
    </script>
</head>
<body>
    <form id="form1" defaultbutton="btnGQuery" runat="server">
		<asp:ScriptManager ID="scriptManager" runat="server"></asp:ScriptManager>
		<script type="text/javascript" language="javascript">
            Sys.WebForms.PageRequestManager.getInstance().add_beginRequest(beginRequest);
            Sys.WebForms.PageRequestManager.getInstance().add_endRequest(endRequest);
        </script>
		<h1>Caching Manager</h1>
		<div id="EditorTabs">
            <a class="activeTab" href="#" rel="GlobalRegion">Global Search</a>
            <a class="normalTab" href="#" rel="SiteRegion">Caches By Site</a>
            <a class="normalTab" href="#" rel="DatabaseRegion">Caches By Database</a>
            <a class="normalTab" href="#" rel="ARRegion">Access Result Caches</a>
            <a class="normalTab" href="#" rel="ProviderRegion">Data Provider Caches</a>
            <a class="normalTab" href="#" rel="MiscRegion">Miscellaneous Caches</a>
        </div>
        <div class="spacer">&nbsp;</div>
        <div class="ActiveRegion GlobalRegion">
			<asp:UpdatePanel ID="upGQuery" runat="server" UpdateMode="Conditional">
				<ContentTemplate>
                    <h2>Cache Information</h2>
			        <div class="Controls">
						<div class="dataRow">
                            Total Cache Size: <span class="title"><asp:Literal ID="ltlSize" runat="server"></asp:Literal></span>
						</div>
                        <div class="dataRow">
                            Cache Entries: <span class="title"><asp:Literal ID="ltlEntries" runat="server"></asp:Literal></span>
						</div>
                        <div class="clear"></div>
			        </div>
                    <h2>Cache Search</h2>
                    <div class="Controls">
                        <div class="fieldHighlight">
                            <asp:TextBox ID="txtGQuery" CssClass="txtQuery" runat="server"></asp:TextBox>				
						    <div class="clear"></div>    
                        </div>
                        <div class="rowSpacer"></div>
                        <div class="fieldHighlight">
							<div class="btnBox">
                                <div class="btn">
                                    <asp:Button ID="btnGQuery" CssClass="searchBtn" rel=".GlobalRegion" Text="Search All Cache" runat="server" OnClick="btnGQuery_Click" />        
                                </div>
                                <div class="btnSpacer">.</div>
                                <div class="btn">
                                    <asp:Button ID="btnGQueryClear" rel=".GlobalRegion" CssClass="BtnClear" Text="Clear Search Results" runat="server" OnClick="btnGQueryClear_Click" Title="(currently works only for Caches with string type key)"/>
                                </div>
                                <div class="btnSpacer">.</div>
                                <div class="btn">
                                    <asp:button ID="ClearAll" rel=".GlobalRegion" CssClass="clearAllBtn" runat="server" Text="Clear All Cache" OnClick="ClearAll_Click"></asp:button>
						        </div>
                            </div>
                            <div class="clear"></div>
							<div class="btnMessage">
								<asp:Literal ID="ltlResults" runat="server"></asp:Literal>
							</div>
					        <asp:Repeater ID="rptGQuery" runat="server">
						        <HeaderTemplate>
									<div class="FormTitleRow">
										<div class="CacheName RowTitle">Cache Name</div>
										<div class="CacheKey RowTitle">Cache Key</div>
										<div class="clear"></div>
									</div>
							        <div class="Results GlobalResults">
						        </HeaderTemplate>
						        <ItemTemplate>
							        <div class="FormRow">
								        <div class="CacheName RowValue">
									        <%# ((System.Web.UI.WebControls.ListItem)Container.DataItem).Text %>
								        </div>
								        <div class="CacheKey RowValue">
									        <%# ((System.Web.UI.WebControls.ListItem)Container.DataItem).Value %>
								        </div>
								        <div class="clear"></div>
							        </div>
						        </ItemTemplate>
						        <FooterTemplate></div></FooterTemplate>
					        </asp:Repeater>
                        </div>
                    </div>
				</ContentTemplate>
			</asp:UpdatePanel>
			<div class="overlay"><div class="message">Loading...</div></div>
			<div class="clear"></div>
		</div>
		<div class="Region SiteRegion">			
            <h2>Search Criteria</h2>
			<div class="Controls">
				<div class="fieldHighlight">
					<div class="FormTitleRow">
						<div class="RowTitle">Type</div>
					</div>
					<div class="clear"></div>
					<div class="btnBox">
						<div class="btn">
							<a href="#" class="selectAll" onclick="CheckAll(this, 'SiteTypeChecks');return false;">Select all - (choose at least one)</a>
						</div>
					</div>
					<div class="SiteTypeChecks">
						<asp:CheckBoxList ID="cblSiteTypes" RepeatColumns="6" runat="server"></asp:CheckBoxList>
					</div>
				</div>
				<div class="rowSpacer"></div>
				<div class="fieldHighlight">
					<div class="FormTitleRow">
						<div class="RowTitle">System Names </div>
					</div>
					<div class="clear"></div>
					<div class="btnBox">
						<div class="btn">
							<a href="#" class="selectAll" onclick="CheckAll(this, 'SysChecks');return false;">Select all - (choose at least one of either system or site name)</a>
						</div>
					</div>
					<div class="SysChecks">
						<asp:CheckBoxList ID="cblSysSiteNames" RepeatColumns="12" runat="server"></asp:CheckBoxList>
					</div>
				</div>
				<div class="rowSpacer"></div>
				<div class="fieldHighlight">
					<div class="FormTitleRow">
						<div class="RowTitle">Site Names</div>
					</div>
					<div class="clear"></div>
					<div class="btnBox">
						<div class="btn">
							<a href="#" class="selectAll" onclick="CheckAll(this, 'SiteChecks');return false;">Select all</a>
						</div>					
					</div>
					<div class="SiteChecks">
						<asp:CheckBoxList ID="cblSiteNames" RepeatColumns="10" runat="server"></asp:CheckBoxList>
					</div>
				</div>
			</div>
			<h2>Search Results</h2>
			<div class="Controls">
				<asp:UpdatePanel ID="UpdatePanel2" UpdateMode="Conditional" runat="server">
					<ContentTemplate>
						<div class="fieldHighlight">
							<div class="btnBox">
								<div class="btn">
									<asp:button ID="btnFetch" rel=".SiteRegion" CssClass="summary" runat="server" Text="Get Summary" OnClick="FetchSiteCacheList"></asp:button>
								</div>
								<div class="btnSpacer">.</div>
								<div class="btn">
									<asp:button ID="Button6" rel=".SiteRegion" CssClass="profile" runat="server" Text="Get Cache Entries" OnClick="FetchSiteCacheProfile"></asp:button>
								</div>
								<div class="btn">
									<asp:button ID="Button6b" rel=".SiteRegion" CssClass="profile" runat="server" Text="Get Cache Content" OnClick="FetchSiteCacheProfileContent"></asp:button>
								</div>
								<div class="btn">
									<asp:button ID="Button6c" rel=".SiteRegion" CssClass="profile" runat="server" Text="Get Cache Content HTML Encode" OnClick="FetchSiteCacheProfileContentEncode"></asp:button>
								</div>
								<div class="btnSpacer">.</div>
								<div class="btn">
									<asp:button ID="Button8" rel=".SiteRegion" CssClass="BtnClear" runat="server" Text="Clear Cache Entries" OnClick="ClearSiteCacheProfile"></asp:button>
								</div>
							</div>
							<div class="CacheList SiteCacheList">
								<asp:Repeater ID="rptSiteCaches" runat="server">
									<HeaderTemplate>
										<div class="FormTitleRow">
											<div class="Name RowTitle">Name</div>
											<div class="Count RowTitle">Cache Entries</div>
											<div class="Size RowTitle">Size</div>
											<div class="MaxSize RowTitle">MaxSize</div>
											<div class="clear"></div>
										</div>
										<div class="Results">
									</HeaderTemplate>
									<ItemTemplate>
										<div class="FormRow <%# GetClass(Container.ItemIndex) %>">
											<div class="Name RowValue"><%# ((MyCache)Container.DataItem).Name %></div>
											<div class="Count RowValue"><%# ((MyCache)Container.DataItem).Count %></div>
											<div class="Size RowValue"><%# GetValFromB(((MyCache)Container.DataItem).Size) %></div>
											<div class="MaxSize RowValue"><%# GetValFromB(((MyCache)Container.DataItem).MaxSize) %></div>
											<div class="clear"></div>
										</div>	
									</ItemTemplate>
									<FooterTemplate>
										</div>
									</FooterTemplate>
								</asp:Repeater>
							</div>
							<div class="ProfileList SiteProfileList">
								<asp:Repeater ID="rptSiteCacheProfiles" OnItemDataBound="rptSCProfiles_DataBound" runat="server">
									<HeaderTemplate>
										<div class="Results">
									</HeaderTemplate>
									<ItemTemplate>
										<div class="FormRow">
											<h3><%# ((MyCache)Container.DataItem).Name %> - 
												<span>Cache Entries:</span> <span class="title"><%# ((MyCache)Container.DataItem).Count %></span>
												<span>Size:</span> <span class="title"><%# GetValFromB(((MyCache)Container.DataItem).Size) %></span>
												<span>MaxSize:</span> <span class="title"><%# GetValFromB(((MyCache)Container.DataItem).MaxSize) %></span>
											</h4>
											<div class="CacheItems">
												<asp:Repeater ID="rptBySite" runat="server">
													<HeaderTemplate>
														<div class="FormRow">
															<div class="CacheID RowTitle">Cache ID</div>
															<div class="clear"></div>
														</div>
													</HeaderTemplate>
													<ItemTemplate>
														<div class="FormRow <%# GetClass(Container.ItemIndex) %>">
															<div class="CacheID"><%# Container.DataItem %></div>
														</div>
													</ItemTemplate>
												</asp:Repeater>
												<asp:Repeater ID="rptBySite2" runat="server">
													<HeaderTemplate>
														<div class="FormRow">
															<div class="CacheID RowTitle">Cache Data</div>
															<div class="clear"></div>
														</div>
													</HeaderTemplate>
													<ItemTemplate>
														<div class="FormRow <%# GetClass(Container.ItemIndex) %>">
															<div class="CacheID"><%# ((KeyValuePair<string,string>)Container.DataItem).Key %><div class="HtmlContent"><%# ((KeyValuePair<string,string>)Container.DataItem).Value %></div></div>
														</div>
													</ItemTemplate>
												</asp:Repeater>
											</div>
										</div>
									</ItemTemplate>
									<FooterTemplate></div></FooterTemplate>
								</asp:Repeater>	
							</div>
						</div>
					</ContentTemplate>
				</asp:UpdatePanel>
				<div class="overlay"><div class="message">Loading...</div></div>	
			</div>
		</div>
		<div class="Region DatabaseRegion">
			<h2>Search Criteria</h2>
			<div class="Controls">
				<div class="fieldHighlight">
					<div class="FormTitleRow"><div class="RowTitle">Types</div></div>
					<div class="clear"></div>
					<div class="btnBox">
						<div class="btn">
							<a href="#" class="selectAll" onclick="CheckAll(this, 'DBTypeChecks');return false;">Select all (choose at least one)</a>
						</div>
					</div>
					<div class="DBTypeChecks">
						<asp:CheckBoxList ID="cblDBTypes" RepeatColumns="6" runat="server"></asp:CheckBoxList>
					</div>
				</div>
				<div class="rowSpacer"></div>
				<div class="fieldHighlight">
					<div class="FormTitleRow"><div class="RowTitle">Database Names</div></div>
					<div class="clear"></div>
					<div class="btnBox">
						<div class="btn">
							<a href="#" class="selectAll" onclick="CheckAll(this, 'DBChecks');return false;">Select all (choose at least one of either system or site name)</a>
						</div>
					</div>
					<div class="DBChecks">
						<asp:CheckBoxList ID="cblDBNames" RepeatColumns="6" runat="server"></asp:CheckBoxList>
					</div>
				</div>
			</div>
			<h2>Search Results</h2>
			<div class="Controls">
				<asp:UpdatePanel ID="UpdatePanel4" UpdateMode="Conditional" runat="server">
					<ContentTemplate>
						<div class="fieldHighlight">
							<div class="btnBox">
								<div class="btn">
									<asp:button ID="Button1" rel=".DatabaseRegion" class="summary" runat="server" Text="Get Summary" OnClick="FetchDBCacheList"></asp:button>
								</div>
								<div class="btnSpacer">.</div>
								<div class="btn">
									<asp:button ID="Button5" rel=".DatabaseRegion" class="profile" runat="server" Text="FetchSiteCacheProfile2" OnClick="FetchDBCacheProfile"></asp:button>
								</div>
								<div class="btnSpacer">.</div>
								<div class="btn">
									<asp:button ID="Button10" rel=".DatabaseRegion" runat="server" CssClass="BtnClear" Text="Clear Cache Entries" OnClick="ClearDBCacheProfile"></asp:button>
								</div>
							</div>
							<div class="CacheList DBCacheList">
								<asp:Repeater ID="rptDBCaches" runat="server">
									<HeaderTemplate>
										<div class="FormTitleRow">
											<div class="Name RowTitle">Name</div>
											<div class="Count RowTitle">Cache Entries</div>
											<div class="Size RowTitle">Size</div>
											<div class="MaxSize RowTitle">MaxSize</div>
											<div class="clear"></div>
										</div>
										<div class="Results">
									</HeaderTemplate>
									<ItemTemplate>
										<div class="FormRow <%# GetClass(Container.ItemIndex) %>">
											<div class="Name RowValue"><%# ((MyCache)Container.DataItem).Name %></div>
											<div class="Count RowValue"><%# ((MyCache)Container.DataItem).Count %></div>
											<div class="Size RowValue"><%# GetValFromB(((MyCache)Container.DataItem).Size) %></div>
											<div class="MaxSize RowValue"><%# GetValFromB(((MyCache)Container.DataItem).MaxSize) %></div>
											<div class="clear"></div>
										</div>
									</ItemTemplate>
									<FooterTemplate></div></FooterTemplate>
								</asp:Repeater>
							</div>
							<div class="ProfileList DBProfileList">
								<asp:Repeater ID="rptDBCacheProfiles" OnItemDataBound="rptSCProfiles_DataBound" runat="server">
									<HeaderTemplate><div class="Results"></HeaderTemplate>
									<ItemTemplate>
										<div class="FormRow">
											<h3><%# ((MyCache)Container.DataItem).Name %> - 
												<span>Cache Entries:</span> <span class="title"><%# ((MyCache)Container.DataItem).Count %></span>
												<span>Size:</span> <span class="title"><%# GetValFromB(((MyCache)Container.DataItem).Size) %></span>
												<span>MaxSize:</span> <span class="title"><%# GetValFromB(((MyCache)Container.DataItem).MaxSize) %></span>
											</h4>
											<div class="CacheItems">
												<asp:Repeater ID="rptBySite" runat="server">
													<HeaderTemplate>
														<div class="FormRow">
															<div class="CacheID RowTitle">Caching ID</div>
															<div class="clear"></div>
														</div>
													</HeaderTemplate>
													<ItemTemplate>
														<div class="FormRow <%# GetClass(Container.ItemIndex) %>">
															<div class="CacheID"><%# Container.DataItem %></div>
														</div>
													</ItemTemplate>
												</asp:Repeater>
											</div>
										</div>
									</ItemTemplate>
									<FooterTemplate></div></FooterTemplate>
								</asp:Repeater>
							</div>
						</div>
					</ContentTemplate>
				</asp:UpdatePanel>
				<div class="overlay"><div class="message">Loading...</div></div>
			</div>
		</div>
		<div class="Region ARRegion">
			<h2>Search Criteria</h2>
			<div class="Controls">
				<div class="fieldHighlight">
					<div class="FormTitleRow"><div class="RowTitle">Cache Names</div></div>
					<div class="clear"></div>
					<div class="btnBox">
						<div class="btn"> 
							<a href="#" class="selectAll" onclick="CheckAll(this, 'ARChecks');return false;">Select all (choose at least one)</a>						
						</div>
					</div>
					<div class="ARChecks">
						<asp:CheckBoxList ID="cblAccessResult" RepeatColumns="6" runat="server"></asp:CheckBoxList>
					</div>
				</div>
			</div>
			<h2>Search Results</h2>
			<div class="Controls">
				<asp:UpdatePanel ID="UpdatePanel64" UpdateMode="Conditional" runat="server">
					<ContentTemplate>
						<div class="fieldHighlight">
							<div class="btnBox">
								<div class="btn">
									<asp:button ID="Button2" rel=".ARRegion" class="summary" runat="server" Text="Get Summary" OnClick="FetchARCacheList"></asp:button>
								</div>
								<div class="btnSpacer">.</div>
								<div class="btn">
									<asp:button ID="Button7" rel=".ARRegion" class="profile" runat="server" Text="Get Cache Entries" OnClick="FetchARCacheProfile"></asp:button>
								</div>
								<div class="btnSpacer">.</div>
								<div class="btn">
									<asp:button ID="Button11" rel=".ARRegion" runat="server" CssClass="BtnClear" Text="Clear Cache Entries" OnClick="ClearARCacheProfile"></asp:button>
								</div>
								<div class="btnSpacer"></div>
							</div>
						</div>
						<div class="CacheList ARCacheList">	
							<asp:Repeater ID="rptARCaches" runat="server">
							<HeaderTemplate>
								<div class="FormTitleRow">
									<div class="Name RowTitle">Name</div>
									<div class="Count RowTitle">Cache Entries</div>
									<div class="Size RowTitle">Size</div>
									<div class="MaxSize RowTitle">MaxSize</div>
									<div class="clear"></div>
								</div>
								<div class="Results">
							</HeaderTemplate>
							<ItemTemplate>
								<div class="FormRow <%# GetClass(Container.ItemIndex) %>">
									<div class="Name RowValue"><%# ((MyCache)Container.DataItem).Name %></div>
									<div class="Count RowValue"><%# ((MyCache)Container.DataItem).Count %></div>
									<div class="Size RowValue"><%# GetValFromB(((MyCache)Container.DataItem).Size) %></div>
									<div class="MaxSize RowValue"><%# GetValFromB(((MyCache)Container.DataItem).MaxSize) %></div>
									<div class="clear"></div>
								</div>	
							</ItemTemplate>
							<FooterTemplate></div></FooterTemplate>
						</asp:Repeater>
						</div>
						<div class="ProfileList ARProfileList">
							<asp:Repeater ID="rptARCacheProfiles" OnItemDataBound="rptSCProfiles_DataBound" runat="server">
								<HeaderTemplate><div class="Results"></HeaderTemplate>
								<ItemTemplate>
									<div class="FormRow">
										<h3><%# ((MyCache)Container.DataItem).Name %> - 
											<span>Cache Entries:</span> <span class="title"><%# ((MyCache)Container.DataItem).Count %></span>
											<span>Size:</span> <span class="title"><%# GetValFromB(((MyCache)Container.DataItem).Size) %></span>
											<span>MaxSize:</span> <span class="title"><%# GetValFromB(((MyCache)Container.DataItem).MaxSize) %></span>
										</h3>
										<div class="CacheItems">
											<asp:Repeater ID="rptBySite" runat="server">
												<HeaderTemplate>
													<div class="FormRow">
														<div class="CacheID RowTitle">Caching ID</div>
														<div class="clear"></div>
													</div>
												</HeaderTemplate>
												<ItemTemplate>
													<div class="FormRow <%# GetClass(Container.ItemIndex) %>">
														<div class="CacheID"><%# Container.DataItem %></div>
													</div>
												</ItemTemplate>
											</asp:Repeater>
										</div>
									</div>
								</ItemTemplate>
								<FooterTemplate></div></FooterTemplate>
							</asp:Repeater>
						</div>
					</ContentTemplate>
				</asp:UpdatePanel>
				<div class="overlay"><div class="message">Loading...</div></div>
			</div>
		</div>
        <div class="Region ProviderRegion">
			<h2>Search Criteria</h2>
			<div class="Controls">
				<div class="fieldHighlight">
					<div class="FormTitleRow"><div class="RowTitle">Cache Names</div></div>
					<div class="clear"></div>
					<div class="btnBox">
						<div class="btn"> 
							<a href="#" class="selectAll" onclick="CheckAll(this, 'ProvChecks');return false;">Select all (choose at least one)</a>						
						</div>
					</div>
					<div class="ProvChecks">
						<asp:CheckBoxList ID="cblProviderResult" RepeatColumns="6" runat="server"></asp:CheckBoxList>
					</div>
				</div>
			</div>
			<h2>Search Results</h2>
			<div class="Controls">
				<asp:UpdatePanel ID="UpdatePanel1" UpdateMode="Conditional" runat="server">
					<ContentTemplate>
						<div class="fieldHighlight">
							<div class="btnBox">
								<div class="btn">
									<asp:button ID="Button9" rel=".ProvRegion" class="summary" runat="server" Text="Get Summary" OnClick="FetchProvCacheList"></asp:button>
								</div>
								<div class="btnSpacer">.</div>
								<div class="btn">
									<asp:button ID="Button12" rel=".ProvRegion" class="profile" runat="server" Text="Get Cache Entries" OnClick="FetchProvCacheProfile"></asp:button>
								</div>
								<div class="btnSpacer">.</div>
								<div class="btn">
									<asp:button ID="Button14" rel=".ProvRegion" runat="server" CssClass="BtnClear" Text="Clear Cache Entries" OnClick="ClearProvCacheProfile"></asp:button>
								</div>
								<div class="btnSpacer"></div>
							</div>
						</div>
						<div class="CacheList ProvCacheList">	
							<asp:Repeater ID="rptProvCaches" runat="server">
							<HeaderTemplate>
								<div class="FormTitleRow">
									<div class="Name RowTitle">Name</div>
									<div class="Count RowTitle">Cache Entries</div>
									<div class="Size RowTitle">Size</div>
									<div class="MaxSize RowTitle">MaxSize</div>
									<div class="clear"></div>
								</div>
								<div class="Results">
							</HeaderTemplate>
							<ItemTemplate>
								<div class="FormRow <%# GetClass(Container.ItemIndex) %>">
									<div class="Name RowValue"><%# ((MyCache)Container.DataItem).Name %></div>
									<div class="Count RowValue"><%# ((MyCache)Container.DataItem).Count %></div>
									<div class="Size RowValue"><%# GetValFromB(((MyCache)Container.DataItem).Size) %></div>
									<div class="MaxSize RowValue"><%# GetValFromB(((MyCache)Container.DataItem).MaxSize) %></div>
									<div class="clear"></div>
								</div>	
							</ItemTemplate>
							<FooterTemplate></div></FooterTemplate>
						</asp:Repeater>
						</div>
						<div class="ProfileList ProvProfileList">
							<asp:Repeater ID="rptProvCacheProfiles" OnItemDataBound="rptSCProfiles_DataBound" runat="server">
								<HeaderTemplate><div class="Results"></HeaderTemplate>
								<ItemTemplate>
									<div class="FormRow">
										<h3><%# ((MyCache)Container.DataItem).Name %> - 
											<span>Cache Entries:</span> <span class="title"><%# ((MyCache)Container.DataItem).Count %></span>
											<span>Size:</span> <span class="title"><%# GetValFromB(((MyCache)Container.DataItem).Size) %></span>
											<span>MaxSize:</span> <span class="title"><%# GetValFromB(((MyCache)Container.DataItem).MaxSize) %></span>
										</h4>
										<div class="CacheItems">
											<asp:Repeater ID="rptBySite" runat="server">
												<HeaderTemplate>
													<div class="FormRow">
														<div class="CacheID RowTitle">Caching ID</div>
														<div class="clear"></div>
													</div>
												</HeaderTemplate>
												<ItemTemplate>
													<div class="FormRow <%# GetClass(Container.ItemIndex) %>">
														<div class="CacheID"><%# Container.DataItem %></div>
													</div>
												</ItemTemplate>
											</asp:Repeater>
										</div>
									</div>
								</ItemTemplate>
								<FooterTemplate></div></FooterTemplate>
							</asp:Repeater>
						</div>
					</ContentTemplate>
				</asp:UpdatePanel>
				<div class="overlay"><div class="message">Loading...</div></div>
			</div>
		</div>
		<div class="Region MiscRegion">
			<h2>Search Criteria</h2>
			<div class="Controls">
				<div class="fieldHighlight">
					<div class="FormTitleRow"><div class="RowTitle">Cache Names</div></div>
					<div class="clear"></div>
					<div class="btnBox">
						<div class="btn">
							<a href="#" class="selectAll" onclick="CheckAll(this, 'MiscChecks');return false;">Select all (choose at least one)</a> 
						</div>
					</div>
					<div class="MiscChecks">
						<asp:CheckBoxList ID="cblMiscNames" RepeatColumns="6" runat="server"></asp:CheckBoxList>
					</div>
				</div>
			</div>
			<h2>Search Results</h2>
			<div class="Controls">
				<asp:UpdatePanel ID="UpdatePanel6" UpdateMode="Conditional" runat="server">
					<ContentTemplate>
						<div class="fieldHighlight">
							<div class="btnBox">
								<div class="btn">
									<asp:button ID="Button3" rel=".MiscRegion" class="summary" runat="server" Text="Get Summary" OnClick="FetchMiscCacheList"></asp:button>
								</div>
								<div class="btnSpacer">.</div>
								<div class="btn">
									<asp:button ID="Button4" rel=".MiscRegion" class="profile" runat="server" Text="Get Cache Entries" OnClick="FetchMiscCacheProfile"></asp:button>
								</div>
								<div class="btnSpacer">.</div>
								<div class="btn">
									<asp:button ID="Button13" rel=".MiscRegion" runat="server" CssClass="BtnClear" Text="Clear Cache Entries" OnClick="ClearMiscCacheProfile"></asp:button>
								</div>
							</div>
							<div class="CacheList MiscCacheList">
								<asp:Repeater ID="rptMiscCaches" runat="server">
									<HeaderTemplate>
										<div class="FormTitleRow">
											<div class="Name RowTitle">Name</div>
											<div class="Count RowTitle">Cache Entries</div>
											<div class="Size RowTitle">Size</div>
											<div class="MaxSize RowTitle">MaxSize</div>
											<div class="clear"></div>
										</div>
										<div class="Results">
									</HeaderTemplate>
									<ItemTemplate>
										<div class="FormRow <%# GetClass(Container.ItemIndex) %>">
											<div class="Name RowValue"><%# ((MyCache)Container.DataItem).Name %></div>
											<div class="Count RowValue"><%# ((MyCache)Container.DataItem).Count %></div>
											<div class="Size RowValue"><%# GetValFromB(((MyCache)Container.DataItem).Size) %></div>
											<div class="MaxSize RowValue"><%# GetValFromB(((MyCache)Container.DataItem).MaxSize) %></div>
											<div class="clear"></div>
										</div>	
									</ItemTemplate>
									<FooterTemplate></div></FooterTemplate>
								</asp:Repeater>
							</div>
							<div class="ProfileList MiscProfileList">
								<asp:Repeater ID="rptMiscCacheProfiles" OnItemDataBound="rptSCProfiles_DataBound" runat="server">
									<HeaderTemplate><div class="Results"></HeaderTemplate>
									<ItemTemplate>
										<div class="FormRow">
											<h3><%# ((MyCache)Container.DataItem).Name %> - 
												<span>Cache Entries:</span> <span class="title"><%# ((MyCache)Container.DataItem).Count %></span>
												<span>Size:</span> <span class="title"><%# GetValFromB(((MyCache)Container.DataItem).Size) %></span>
												<span>MaxSize:</span> <span class="title"><%# GetValFromB(((MyCache)Container.DataItem).MaxSize) %></span>
											</h4>
											<div class="CacheItems">
												<asp:Repeater ID="rptBySite" runat="server">
													<HeaderTemplate>
														<div class="FormRow">
															<div class="CacheID RowTitle">Caching ID</div>
															<div class="clear"></div>
														</div>
													</HeaderTemplate>
													<ItemTemplate>
														<div class="FormRow <%# GetClass(Container.ItemIndex) %>">
															<div class="CacheID"><%# Container.DataItem %></div>
														</div>
													</ItemTemplate>
												</asp:Repeater>
											</div>
										</div>
									</ItemTemplate>
									<FooterTemplate></div></FooterTemplate>
								</asp:Repeater>
							</div>
						</div>
					</ContentTemplate>
				</asp:UpdatePanel>
				<div class="overlay"><div class="message">Loading...</div></div>
			</div>
		</div>
    </form>
</body>
</html>