#!/usr/bin/env python3
"""Atualiza o indice do corpo do relatorio e exporta-o para PDF com o LibreOffice (UNO).

Uso: python3 render.py <entrada.docx> <saida.docx> <saida.pdf>
Abre o LibreOffice em modo headless, atualiza os campos e o indice (o docx gerado pelo
docx-js traz o indice vazio), grava o .docx atualizado e o .pdf.
"""
import os, sys, time, subprocess, tempfile, uno
from com.sun.star.beans import PropertyValue

def prop(n, v):
    p = PropertyValue(); p.Name = n; p.Value = v; return p

ent, sai_docx, sai_pdf = map(os.path.abspath, sys.argv[1:4])
perfil = tempfile.mkdtemp(prefix='lo_perfil_')
porta = '2002'
proc = subprocess.Popen(['soffice', '--headless', '--invisible', '--norestore', f'-env:UserInstallation=file://{perfil}',
                         f'--accept=socket,host=localhost,port={porta};urp;'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
local = uno.getComponentContext()
res = local.ServiceManager.createInstanceWithContext('com.sun.star.bridge.UnoUrlResolver', local)
for _ in range(60):
    try:
        ctx = res.resolve(f'uno:socket,host=localhost,port={porta};urp;StarOffice.ComponentContext'); break
    except Exception:
        time.sleep(0.5)
desktop = ctx.ServiceManager.createInstanceWithContext('com.sun.star.frame.Desktop', ctx)
doc = desktop.loadComponentFromURL(uno.systemPathToFileUrl(ent), '_blank', 0, (prop('Hidden', True),))
for _ in range(2):                      # duas vezes: o indice muda a paginacao
    idx = doc.getDocumentIndexes()
    for i in range(idx.getCount()):
        idx.getByIndex(i).update()
    doc.getTextFields().refresh()
doc.storeToURL(uno.systemPathToFileUrl(sai_docx), (prop('FilterName', 'MS Word 2007 XML'),))
doc.storeToURL(uno.systemPathToFileUrl(sai_pdf), (prop('FilterName', 'writer_pdf_Export'),))
doc.close(True)
try:
    desktop.terminate()
except Exception:
    pass
proc.wait(timeout=30)
print(sai_docx); print(sai_pdf)
