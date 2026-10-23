// Write an N-page A4 PDF of blank pages: make_pdf.js <pages> <out.pdf>
ObjC.import('Foundation')
ObjC.import('PDFKit')

function run(argv) {
	const out = $.PDFDocument.alloc.init
	for (let i = 0; i < Number(argv[0]); i++) {
		const page = $.PDFPage.alloc.init
		page.setBoundsForBox($.NSMakeRect(0, 0, 595, 842), $.kPDFDisplayBoxMediaBox)
		out.insertPageAtIndex(page, i)
	}
	if (!out.writeToFile(argv[1])) throw new Error('Cannot write ' + argv[1])
}
