SELECT name, pkg_name, version, version_code, download_count, average_rating, star_1_rating_count, star_2_rating_count, star_3_rating_count, star_4_rating_count, star_5_rating_count, total_star_rating_count
	FROM public.app_info
	order by download_count desc
	limit 100;