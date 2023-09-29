build._base.hxml

-dce std
--macro hxd.res.Config.addIgnoredDir("exportWAV")
--cmd php bin/js/index.php > bin/js/index.html