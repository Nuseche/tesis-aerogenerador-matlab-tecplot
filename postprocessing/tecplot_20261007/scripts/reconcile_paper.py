"""Recover the expanded article and install explanatory Tecplot figures.

The archived Overleaf Spanish manuscript is the content baseline. Its display
equations are preserved; English prose is aligned paragraph by paragraph.
"""
from common import *
from paper_translation_en import T
import zipfile,shutil
from functools import lru_cache
from PIL import Image,ImageChops
from pypdf import PdfReader

PAPER=ROOT/'docs/formulacion_revista_20260919'
ARCHIVE=HERE/'archive/paper_before_figure_reconciliation_20261008.zip'
FIGURES={
 'modelo':('turbina_3d',False,'.92','.31'),
 'cambio-componentes':('concept_cambio-componentes',True,'.90','.30'),
 'sistemas-globales':('concept_sistemas-lateral',True,'.83','.35'),
 'giro-nominal':('concept_cubo-nominal',True,'.70','.29'),
 'marcos':('concept_marcos',True,'.83','.37'),
 'viga':('concept_particula-seccion',True,'.96','.34'),
 'cortante':('concept_shear',True,'.82','.32'),
 'configuraciones':('concept_tresniveles',True,'.98','.24'),
 'masa-seccional':('paper_masa_seccional',True,'.76','.30'),
 'elemento':('concept_elemento',True,'.82','.32'),
 'vinculo-raiz':('paper_vinculo_raiz',True,'.86','.31'),
}
CAP_ES={
 'modelo':r'Idealización estructural del aerogenerador: torre y palas flexibles, góndola y cubo rígidos. Las líneas y los nodos interiores identifican el modelo de vigas. Las envolventes exteriores son ilustrativas y no constituyen una malla de sólidos ni geometría CAD.',
 'cambio-componentes':r'Un mismo vector $\bm a$ expresado en las bases (a) $A$ y (b) $B$. Las líneas auxiliares muestran sus proyecciones. La transformación $\bm a^A=\bm Q_{AB}\bm a^B$ cambia las componentes y conserva el vector geométrico.',
 'sistemas-globales':r'Orígenes y triedros de referencia en una vista espacial, con azimut nominal nulo. Los ejes de $B$ y $G$ son paralelos a los inerciales; $\bm c_B(t)$ localiza la base. El superíndice $H,n$ identifica el triedro nominal del cubo. Las separaciones y los volúmenes son esquemáticos.',
 'giro-nominal':r'Rotación nominal del cubo alrededor del eje 1 común. Los ejes inerciales 2 y 3 son discontinuos; los nominales $H,n$ son continuos. El arco $\psi$ sigue la regla de la mano derecha. La orientación nominal puede ser grande, independientemente de las pequeñas rotaciones estructurales.',
 'marcos':r'Triedros de las tres raíces para $\psi=0$. El director $\bm d_{1b}$ es longitudinal, $\bm d_{2b}$ es tangencial y $\bm d_{3b}=\bm E_1$ completa la base dextrógira. Las raíces $P_b$ están separadas $120^\circ$ alrededor de $O_H$.',
 'viga':r'Posición de una partícula de viga: (a) línea $\bm r(S,t)$ y orientación de la sección; (b) detalle de la sección, donde $\bm x_P=\bm r+\xi_2\bm d_2+\xi_3\bm d_3$. La envolvente transparente permite ver la línea de referencia; sus superficies no añaden grados de libertad.',
 'cortante':r'Independencia entre la normal seccional $\bm d_1$ y la tangente $\bm t$ a la línea de referencia. El ángulo $\gamma$ ilustra el cortante en el plano del dibujo; es una componente angular ilustrativa, no el vector completo de deformaciones $\bm\gamma$ de la ecuación~\eqref{eq:medidas-viga}.',
 'configuraciones':r'Una misma porción material en (a) referencia, (b) movimiento nominal y (c) configuración perturbada. En (c), el contorno discontinuo reproduce la configuración nominal y la flecha $\bm u$ señala la diferencia en el extremo. $\bm x_{\rm nom}$ representa $\overline{\bm x}$; los desplazamientos están ampliados para distinguir los estados.',
 'masa-seccional':r'Geometría de la integración de masa: origen seccional $O$, centro de masa $C$ y contribución $\dd\mu=\rho_0\dd A$. La posición de la partícula satisface $\bm r_P=\bm r_C+\bm\rho_C$. La inercia centroidal usa $\bm\rho_C$; su traslado al origen utiliza $\bm r_C$. El espesor de la sección es ilustrativo.',
 'elemento':r'Orientación de un elemento entre $I$ y $J$. El eje $\bm e_1$ sigue la cuerda; la proyección $\bm p$ del punto auxiliar $\bm X_a$ sobre el plano normal determina $\bm e_3$. Se completa el triedro con $\bm e_2=\bm e_3\times\bm e_1$. El punto auxiliar no es un nodo estructural.',
 'vinculo-raiz':r'Compatibilidad incremental entre el maestro $m=H$ y la raíz $s$. Las flechas sucesivas representan $\delta\bm u_m$ y $\delta\bm u_{\rm rot}=\delta\bm\theta_m\times\bm r_s$; la flecha directa representa su suma $\delta\bm u_s$. El punto intermedio incorpora solamente la traslación común del cubo.',
}
CAP_EN={
 'modelo':r'Wind turbine structural idealization: flexible tower and blades, rigid nacelle and hub. Interior lines and nodes identify the beam model. Exterior envelopes are illustrative and represent neither a solid mesh nor CAD geometry.',
 'cambio-componentes':r'The same vector $\bm a$ expressed in bases (a) $A$ and (b) $B$. Auxiliary lines show its projections. Transformation $\bm a^A=\bm Q_{AB}\bm a^B$ changes components while preserving the geometric vector.',
 'sistemas-globales':r'Reference origins and triads in a spatial view at zero nominal azimuth. The axes of $B$ and $G$ are parallel to the inertial axes; $\bm c_B(t)$ locates the base. Superscript $H,n$ identifies the nominal hub triad. Separations and volumes are schematic.',
 'giro-nominal':r'Nominal hub rotation about the common axis 1. Inertial axes 2 and 3 are dashed; nominal axes $H,n$ are solid. Arc $\psi$ follows the right-hand rule. Nominal orientation may be large independently of small structural rotations.',
 'marcos':r'The three root triads at $\psi=0$. Director $\bm d_{1b}$ is longitudinal, $\bm d_{2b}$ is tangential, and $\bm d_{3b}=\bm E_1$ completes the right-handed basis. Roots $P_b$ are separated by $120^\circ$ about $O_H$.',
 'viga':r'Beam-particle position: (a) line $\bm r(S,t)$ and section orientation; (b) sectional detail, where $\bm x_P=\bm r+\xi_2\bm d_2+\xi_3\bm d_3$. The transparent envelope reveals the reference line; its surfaces add no degrees of freedom.',
 'cortante':r'Independence of section normal $\bm d_1$ and reference-line tangent $\bm t$. Angle $\gamma$ illustrates shear in the drawing plane; it is an illustrative angular component, rather than the complete strain vector $\bm\gamma$ in Eq.~\eqref{eq:medidas-viga}.',
 'configuraciones':r'The same material portion in (a) reference, (b) nominal motion, and (c) perturbed configuration. In (c), the dashed contour repeats the nominal configuration, and arrow $\bm u$ indicates the endpoint difference. Here, $\bm x_{\rm nom}$ denotes $\overline{\bm x}$; displacements are enlarged to distinguish the states.',
 'masa-seccional':r'Mass-integration geometry: section origin $O$, center of mass $C$, and contribution $\dd\mu=\rho_0\dd A$. Particle position satisfies $\bm r_P=\bm r_C+\bm\rho_C$. Centroidal inertia uses $\bm\rho_C$; transfer to the origin uses $\bm r_C$. Section thickness is illustrative.',
 'elemento':r'Orientation of an element between $I$ and $J$. Axis $\bm e_1$ follows the chord; projection $\bm p$ of auxiliary point $\bm X_a$ onto the normal plane determines $\bm e_3$. The triad is completed by $\bm e_2=\bm e_3\times\bm e_1$. The auxiliary point is not a structural node.',
 'vinculo-raiz':r'Incremental compatibility between master $m=H$ and root $s$. Successive arrows represent $\delta\bm u_m$ and $\delta\bm u_{\rm rot}=\delta\bm\theta_m\times\bm r_s$; the direct arrow represents their sum $\delta\bm u_s$. The intermediate point includes only common hub translation.',
}

@lru_cache(None)
def blank_margins(asset):
    """Trim only the native export's white surround, retaining 6 bp padding.

    The PNG pixels and native geometry remain unchanged. LaTeX clips the PDF
    viewport so unused frame space cannot shrink the scientific annotation.
    """
    im=Image.open(HERE/'figures'/f'{asset}.png').convert('RGB')
    x0,y0,x1,y1=ImageChops.difference(im,Image.new('RGB',im.size,'white')).getbbox()
    page=PdfReader(HERE/'figures'/f'{asset}.pdf').pages[0]
    w,h=float(page.mediabox.width),float(page.mediabox.height)
    margins=[x0/im.width*w,(im.height-y1)/im.height*h,(im.width-x1)/im.width*w,y0/im.height*h]
    return ' '.join(f'{max(0,m-6):.3f}bp' for m in margins)

def figure(key,lang):
    asset,wide,width,height=FIGURES[key];env='figure*' if wide else 'figure';dim='textwidth' if wide else 'columnwidth'
    cap=(CAP_ES if lang=='es' else CAP_EN)[key]
    return '\\begin{'+env+'}[tp]\n\\centering\n\\includegraphics[trim={'+blank_margins(asset)+'},clip,width='+width+'\\'+dim+',height='+height+'\\textheight,keepaspectratio]{figures/tecplot/'+asset+'.pdf}\n\\caption{'+cap+'}\\label{fig:'+key+'}\n\\end{'+env+'}'

def restore_body(lang):
    chunks=json.loads((HERE/'reports/paper_translation_chunks.json').read_text());math=json.loads((HERE/'reports/paper_math_blocks.json').read_text())
    if lang=='en':chunks=[p if p.startswith(('@@','%')) else T[i] for i,p in enumerate(chunks)]
    else:
        chunks[3]=chunks[3].replace('identifica los componentes y la transmisión del movimiento de base.','identifica los componentes; el movimiento de base se transmite a través de la torre.')
        chunks[17]=chunks[17].split('La figura~')[0]+r'La figura~\ref{fig:sistemas-globales} sitúa los orígenes y las tres direcciones de cada triedro en el espacio. La figura~\ref{fig:giro-nominal} muestra la rotación de los ejes del cubo respecto de los inerciales. El superíndice $H,n$ en los dibujos identifica la orientación nominal representada con una barra superior en el texto.'
        chunks[31]=r'La figura~\ref{fig:viga} localiza una partícula mediante la línea de referencia y los directores de la sección. La figura~\ref{fig:cortante} distingue la normal seccional de la tangente, haciendo explícita su independencia cinemática.'
        chunks[77]=r'La figura~\ref{fig:elemento} identifica los extremos del elemento y la dirección auxiliar proyectada que construye su base espacial. El punto auxiliar solo fija los ejes transversales; no es un nodo con grados de libertad.'
    s='\n\n'.join(chunks)+'\n'
    for i,m in enumerate(math):s=s.replace('@@MATH'+str(i)+'@@',m.replace(r'\text{constante}',r'\text{constant}') if lang=='en' else m)
    for key in FIGURES:
        marker='% FIGURE '+key
        if marker in s:s=s.replace(marker,figure(key,lang))
    for after,extra in [('sistemas-globales','giro-nominal'),('viga','cortante')]:s=s.replace(figure(after,lang),figure(after,lang)+'\n\n'+figure(extra,lang))
    assert '@@MATH' not in s and '% FIGURE' not in s
    return s

def main():
    with zipfile.ZipFile(ARCHIVE) as z:
        expanded=z.read('output/latex/FCEFyN_Overleaf/FCEFyN_ES.tex').decode()
        prefix=expanded[:expanded.index(r'\section{Introducción}')]
        prefix=prefix.replace(r'\usepackage{bm,tikz,placeins}',r'\usepackage{bm,placeins}')
        prefix=re.sub(r'\\usetikzlibrary.*?(?=\\setkeys\{Gin\})','',prefix,flags=re.S)
        prefix=prefix.replace('skip=12pt','skip=8pt').replace('{\\belowcaptionskip}{6pt}','{\\belowcaptionskip}{4pt}')
        prefix=prefix.replace('24pt plus 4pt minus 2pt','18pt plus 4pt minus 2pt').replace('22pt plus 4pt minus 2pt','18pt plus 4pt minus 2pt')
        # Retain the class, author metadata, latest title and abstracts.
        for lang in ['es','en']:
            pfx=prefix
            if lang=='en':
                pfx=pfx.replace(r'\PassOptionsToPackage{english}{babel}'+'\n','').replace(r'\documentclass[esp]',r'\documentclass[eng]').replace(r'\selectlanguage{spanish}',r'\selectlanguage{english}')
                title=re.search(r'\\title\{(.*?)\}\n',pfx,re.S).group(1).split('\\\\');pfx=re.sub(r'\\title\{.*?\}\n',lambda m:'\\title{'+title[1]+'\\\\'+title[0]+'}\n',pfx,flags=re.S)
                pfx=pfx.replace('Dinámica estructural de un aerogenerador','Wind turbine structural dynamics').replace('pdftitle={Formulación matemática de la dinámica estructural de un aerogenerador con rotación prescrita}','pdftitle={Mathematical formulation of wind turbine structural dynamics with prescribed rotation}').replace('no consignado','not provided').replace('Autor de correspondencia:','Corresponding author:')
                pfx=re.sub(r'\\resumen\{(.*?)\}\n\\palabrasclave',lambda m:r'\resumen{\foreignlanguage{spanish}{'+m.group(1)+'}}\n\\palabrasclave',pfx,flags=re.S)
            (PAPER/f'cuerpo_{lang}.tex').write_text(restore_body(lang))
            (PAPER/f'FCEFyN_{lang.upper()}.tex').write_text(pfx+'\\input{cuerpo_'+lang+'}\n\\insertbibliography{Referencias}\n\\end{document}\n')
        (PAPER/'Referencias.bib').write_bytes(z.read('output/latex/FCEFyN_Overleaf/Referencias.bib'))
    install_figures(PAPER)
    synchronize()
    dump(HERE/'reports/paper_reconciliation.json',{
        'canonical_source':str(PAPER),'baseline':'Expanded Spanish manuscript recovered from output/latex/FCEFyN_Overleaf; archived before revision.',
        'previous_compact_figure_count':1,'retained_original_figure_labels':9,'current_figure_count':len(FIGURES),
        'added_explanatory_views':['Nominal hub rotation in its own readable figure','Section normal versus reference-line tangent'],
        'display_math_blocks_preserved':84,'bilingual_translation_paragraphs':len(T),
        'figures':{k:v[0] for k,v in FIGURES.items()},'solver_changes':0})

def install_figures(dest):
    folder=dest/'figures/tecplot';folder.mkdir(parents=True,exist_ok=True)
    for asset,*_ in FIGURES.values():shutil.copy2(HERE/'figures'/f'{asset}.pdf',folder/f'{asset}.pdf')

def synchronize():
    for name in ['FCEFyN_Formulacion_Bilingue','FCEFyN_Overleaf']:
        dest=ROOT/'output/latex'/name;dest.mkdir(parents=True,exist_ok=True)
        for lang in ['ES','EN']:
            s=(PAPER/f'FCEFyN_{lang}.tex').read_text();body=(PAPER/f'cuerpo_{lang.lower()}.tex').read_text()
            (dest/f'FCEFyN_{lang}.tex').write_text(s.replace('\\input{cuerpo_'+lang.lower()+'}',body))
        shutil.copy2(PAPER/'Referencias.bib',dest/'Referencias.bib');install_figures(dest)
    p=HERE/'reports/updated_documents.json';docs=json.loads(p.read_text())
    for lang in ['ES','EN']:
        s=str(ROOT/f'output/latex/FCEFyN_Overleaf/FCEFyN_{lang}.tex')
        if s not in docs:docs.append(s)
    dump(p,docs)

if __name__=='__main__':main()
