using System.Globalization;
using System.Text;

namespace PhehelloEnrollmentSchool.Services
{
    public sealed class LetterContent
    {
        public string SchoolName { get; init; } = "";
        public string Address { get; init; } = "";
        public string Telephone { get; init; } = "";
        public bool Approved { get; init; }
        public string LearnerName { get; init; } = "";
        public string IdNumber { get; init; } = "";
        public string? StudentNumber { get; init; }
        public string? Grade { get; init; }
        public string ApplicationRef { get; init; } = "";
        public DateTime IssuedOn { get; init; }

        public string Heading => Approved ? "CONFIRMATION OF ENROLMENT" : "OUTCOME OF APPLICATION";

        public string Intro => Approved
            ? "We are pleased to confirm the successful enrolment of:"
            : "We regret to inform you that the application for enrolment of:";

        public string Closing => Approved
            ? "Please keep this letter safe. The student number above is unique to the learner and " +
              "may be verified against the school's records."
            : "If you have any questions about this outcome, please contact the school office.";
    }

    /// <summary>
    /// Builds the one-page A4 confirmation letter (FR12) as a PDF with no third-party library:
    /// school crest, learner name, ID number and student number.
    /// </summary>
    public sealed class ConfirmationLetterPdf
    {
        private const double PageW = 595, PageH = 842;
        private readonly string _crestPath;

        public ConfirmationLetterPdf(IWebHostEnvironment env)
        {
            _crestPath = Path.Combine(env.WebRootPath ?? Path.Combine(env.ContentRootPath, "wwwroot"), "img", "crest-letter.jpg");
        }

        // Colours
        private const string Brown = "0.357 0.227 0.161";
        private const string Gold = "0.788 0.635 0.153";
        private const string Ink = "0.231 0.141 0.094";
        private const string Muted = "0.42 0.36 0.32";

        public byte[] Build(LetterContent c)
        {
            var cs = new StringBuilder();

            // Frame
            cs.Append("0.85 0.80 0.72 RG 0.8 w 36 36 523 770 re S\n");

            // School name
            Centered(cs, c.SchoolName.ToUpperInvariant(), bold: true, size: 20, y: 760, color: Brown);

            // Crest
            var crest = LoadJpeg();
            if (crest != null)
            {
                const double h = 130;
                var w = h * crest.Value.Width / crest.Value.Height;
                cs.Append($"q {F(w)} 0 0 {F(h)} {F((PageW - w) / 2)} 610 cm /Im1 Do Q\n");
            }

            Centered(cs, c.Heading, bold: true, size: 11, y: 584, color: Gold, charSpace: 1.6);
            cs.Append($"0.85 0.80 0.72 RG 0.6 w 130 568 m 465 568 l S\n");

            Centered(cs, "Dear Parent / Guardian", bold: false, size: 12, y: 535, color: Ink);
            Centered(cs, c.Intro, bold: false, size: 11, y: 508, color: Muted);

            Centered(cs, c.LearnerName, bold: true, size: 20, y: 474, color: Brown);

            var y = 446.0;
            if (c.Approved && !string.IsNullOrWhiteSpace(c.StudentNumber))
            {
                Centered(cs, $"Student Number: {c.StudentNumber}", bold: true, size: 12, y: y, color: Ink);
                y -= 20;
            }
            if (!string.IsNullOrWhiteSpace(c.IdNumber))
            {
                Centered(cs, $"ID Number: {c.IdNumber}", bold: false, size: 11, y: y, color: Ink);
                y -= 18;
            }
            if (!string.IsNullOrWhiteSpace(c.Grade))
            {
                Centered(cs, $"Grade applied for: {c.Grade}", bold: false, size: 11, y: y, color: Ink);
                y -= 18;
            }
            Centered(cs, $"Application reference: {c.ApplicationRef}", bold: false, size: 11, y: y, color: Ink);
            y -= 40;

            foreach (var line in Wrap(c.Closing, false, 10.5, 380))
            {
                Centered(cs, line, bold: false, size: 10.5, y: y, color: Muted);
                y -= 15;
            }

            // Date and signature
            Centered(cs, $"Issued on {c.IssuedOn.ToString("d MMMM yyyy", CultureInfo.InvariantCulture)}",
                bold: false, size: 10.5, y: 250, color: Ink);
            cs.Append("0.35 0.25 0.20 RG 0.6 w 205 200 m 390 200 l S\n");
            Centered(cs, "Administrator", bold: true, size: 10.5, y: 185, color: Ink);
            Centered(cs, c.SchoolName, bold: false, size: 9.5, y: 171, color: Muted);

            // Footer
            var footer = string.Join("   |   ", new[] { c.Address, string.IsNullOrWhiteSpace(c.Telephone) ? "" : "Tel: " + c.Telephone }
                .Where(x => !string.IsNullOrWhiteSpace(x)));
            if (footer.Length > 0)
                Centered(cs, footer, bold: false, size: 8.5, y: 60, color: Muted);

            return Assemble(cs.ToString(), crest);
        }

        // ------------------------------------------------------------ PDF writer

        private static byte[] Assemble(string content, (byte[] Data, int Width, int Height)? image)
        {
            var objects = new List<byte[]>();
            byte[] Str(string s) => Encoding.Latin1.GetBytes(s);

            objects.Add(Str("<< /Type /Catalog /Pages 2 0 R >>"));
            objects.Add(Str("<< /Type /Pages /Kids [3 0 R] /Count 1 >>"));

            var xobj = image != null ? " /XObject << /Im1 7 0 R >>" : "";
            objects.Add(Str($"<< /Type /Page /Parent 2 0 R /MediaBox [0 0 {F(PageW)} {F(PageH)}] " +
                            $"/Contents 4 0 R /Resources << /Font << /F1 5 0 R /F2 6 0 R >>{xobj} >> >>"));

            var contentBytes = Str(content);
            var stream = new MemoryStream();
            stream.Write(Str($"<< /Length {contentBytes.Length} >>\nstream\n"));
            stream.Write(contentBytes);
            stream.Write(Str("\nendstream"));
            objects.Add(stream.ToArray());

            objects.Add(Str("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>"));
            objects.Add(Str("<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>"));

            if (image != null)
            {
                var img = new MemoryStream();
                img.Write(Str($"<< /Type /XObject /Subtype /Image /Width {image.Value.Width} /Height {image.Value.Height} " +
                              $"/ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /DCTDecode /Length {image.Value.Data.Length} >>\nstream\n"));
                img.Write(image.Value.Data);
                img.Write(Str("\nendstream"));
                objects.Add(img.ToArray());
            }

            using var pdf = new MemoryStream();
            pdf.Write(Str("%PDF-1.4\n%\u00e2\u00e3\u00cf\u00d3\n"));
            var offsets = new List<long>();
            for (var i = 0; i < objects.Count; i++)
            {
                offsets.Add(pdf.Position);
                pdf.Write(Str($"{i + 1} 0 obj\n"));
                pdf.Write(objects[i]);
                pdf.Write(Str("\nendobj\n"));
            }

            var xref = pdf.Position;
            pdf.Write(Str($"xref\n0 {objects.Count + 1}\n0000000000 65535 f \n"));
            foreach (var o in offsets) pdf.Write(Str($"{o:0000000000} 00000 n \n"));
            pdf.Write(Str($"trailer\n<< /Size {objects.Count + 1} /Root 1 0 R >>\nstartxref\n{xref}\n%%EOF"));
            return pdf.ToArray();
        }

        // ------------------------------------------------------------ text helpers

        private static void Centered(StringBuilder cs, string text, bool bold, double size, double y, string color, double charSpace = 0)
        {
            var width = Measure(text, bold, size) + charSpace * Math.Max(0, text.Length - 1);
            var x = Math.Max(48, (PageW - width) / 2);
            cs.Append($"BT {(bold ? "/F2" : "/F1")} {F(size)} Tf {color} rg ");
            // Tc persists in the PDF graphics state, so always set it (0 resets earlier spacing).
            cs.Append($"{F(charSpace)} Tc ");
            cs.Append($"{F(x)} {F(y)} Td ({Escape(text)}) Tj ET\n");
        }

        private static IEnumerable<string> Wrap(string text, bool bold, double size, double maxWidth)
        {
            var line = new StringBuilder();
            foreach (var word in text.Split(' ', StringSplitOptions.RemoveEmptyEntries))
            {
                var candidate = line.Length == 0 ? word : line + " " + word;
                if (Measure(candidate, bold, size) > maxWidth && line.Length > 0)
                {
                    yield return line.ToString();
                    line.Clear();
                    line.Append(word);
                }
                else
                {
                    line.Clear();
                    line.Append(candidate);
                }
            }
            if (line.Length > 0) yield return line.ToString();
        }

        private static string Escape(string s)
        {
            var sb = new StringBuilder();
            foreach (var ch in s)
            {
                var c = ch > 255 ? '?' : ch;
                if (c is '\\' or '(' or ')') sb.Append('\\');
                if (c < 32) continue;
                sb.Append(c);
            }
            return sb.ToString();
        }

        private static string F(double v) => v.ToString("0.##", CultureInfo.InvariantCulture);

        // Standard Helvetica / Helvetica-Bold advance widths for ASCII 32..126 (per 1000 em).
        private static readonly int[] Regular =
        {
            278,278,355,556,556,889,667,191,333,333,389,584,278,333,278,278,
            556,556,556,556,556,556,556,556,556,556,278,278,584,584,584,556,
            1015,667,667,722,722,667,611,778,722,278,500,667,556,833,722,778,
            667,778,722,667,611,722,667,944,667,667,611,278,278,278,469,556,
            333,556,556,500,556,556,278,556,556,222,222,500,222,833,556,556,
            556,556,333,500,278,556,500,722,500,500,500,334,260,334,584
        };

        private static readonly int[] Bold =
        {
            278,333,474,556,556,889,722,238,333,333,389,584,278,333,278,278,
            556,556,556,556,556,556,556,556,556,556,333,333,584,584,584,611,
            975,722,722,722,722,667,611,778,722,278,556,722,611,833,722,778,
            667,778,722,667,611,722,667,944,667,667,611,333,278,333,584,556,
            333,556,611,556,611,556,333,611,611,278,278,556,278,889,611,611,
            611,611,389,556,333,611,556,778,556,556,500,389,280,389,584
        };

        private static double Measure(string text, bool bold, double size)
        {
            var table = bold ? Bold : Regular;
            double total = 0;
            foreach (var ch in text)
                total += ch is >= ' ' and <= '~' ? table[ch - ' '] : 556;
            return total * size / 1000.0;
        }

        // ------------------------------------------------------------ crest image

        private (byte[] Data, int Width, int Height)? LoadJpeg()
        {
            try
            {
                if (!File.Exists(_crestPath)) return null;
                var data = File.ReadAllBytes(_crestPath);

                // Find the Start-Of-Frame marker to read the pixel size.
                var i = 2;
                while (i + 9 < data.Length)
                {
                    if (data[i] != 0xFF) { i++; continue; }
                    var marker = data[i + 1];
                    if (marker is >= 0xC0 and <= 0xCF and not 0xC4 and not 0xC8 and not 0xCC)
                    {
                        var height = (data[i + 5] << 8) | data[i + 6];
                        var width = (data[i + 7] << 8) | data[i + 8];
                        return (data, width, height);
                    }
                    var len = (data[i + 2] << 8) | data[i + 3];
                    i += 2 + len;
                }
            }
            catch (IOException) { }
            return null;
        }
    }
}
