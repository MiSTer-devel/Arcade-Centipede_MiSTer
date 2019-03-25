main()
{
	int vc, va, m;
	int lines, frames;
	int old_h, old_v, h, v;
	int hwidth, vwidth, hcount, hpixels;

	lines = 0;
	frames = 0;
	old_h = 0;
	old_v = 0;
	hwidth = 0;
	vwidth = 0;
	hcount = 0;
	hpixels = 0;

	for (vc = 0; vc < 16640; vc++) {
		m = (vc & 0x4000) ? 0x3f00 : 0;
		va = (vc & 0x3fff) | m;

		printf("%5d %05x %05x %05x ", vc, vc, m, va);
		h = 0;
		v = 0;

//		if ((va & 0x0001e) == 0x0001c) { printf("H"); hwidth++; h=1; } else hcount++;
		if ((vc & 0x0001f) == 0x0001e ||
		    (vc & 0x0001f) == 0x0001c ||
		    (vc & 0x0001f) == 0x0001d
			) { printf("H%d", lines); hwidth++; h=1; } else hcount++;

//		if ((vc & 0x07e00) == 0x03e00)
//		if ((vc & 0x03e00) == 0x03e00)
		if ((vc & 0x07ff0) == 0x03f20 ||
		    (vc & 0x07ff0) == 0x03f30 ||
		    (vc & 0x07ff0) == 0x03f40 ||
		    (vc & 0x07ff0) == 0x03f50)
		{ printf("V"); v=1; }

		printf("\n");

		if (h && old_h == 0) {
			hpixels = hcount;
			hwidth = 1;
			lines++;
			hcount = 0;
			if (v) vwidth++; 
		}
		old_h = h;

		if (v && old_v == 0) {
			vwidth = 1;
			frames++;
		}
		old_v = v;
	}
	printf("lines %d\n", lines);
	printf("frames %d\n", frames);
	printf("hwidth %d\n", hwidth);
	printf("vwidth %d\n", vwidth);
	printf("hpixels %d\n", hpixels);
}

