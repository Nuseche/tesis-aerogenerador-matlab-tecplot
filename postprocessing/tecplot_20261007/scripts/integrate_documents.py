"""Install native vector exports and synchronize the existing LaTeX documents.

Uses the existing formulation and stored evidence; no simulation is launched.
"""
from common import *
import shutil

CAPTIONS={
'configs':r'Una misma partícula en las configuraciones de referencia y actual. Los vectores $\vct X$ y $\vct x$ se miden desde $O_N$ y su diferencia define $\vct u$. Las envolventes transparentes identifican el cuerpo material; la geometría es ilustrativa.',
'cambio-componentes':r'Un mismo vector espacial $\vct a$ expresado en las bases $A$ y $B$, representadas por separado en (a) y (b). Las líneas auxiliares relacionan la punta con sus proyecciones sobre cada eje. Cambian las componentes $a_i^A$ y $a_i^B$, mientras se conserva el vector geométrico.',
'frames':r'Cambio de origen y de base en el espacio. Los tres ejes de cada triedro permiten distinguir orientación y posición. Se cumple $\vct x=\vct c_B+\vct y$ como identidad vectorial; en componentes de $A$, ${}^A\vct x={}^A\vct c_B+{}^AQ_B{}^B\vct y$.',
'rotaciones-elementales':r'Rotaciones elementales en tres dimensiones: (a) $R_1(\alpha)$, (b) $R_2(\beta)$ y (c) $R_3(\gamma)$. Las direcciones iniciales se trazan discontinuas en gris y sus imágenes continuas en negro. El eje de giro permanece inalterado; los arcos siguen la regla de la mano derecha. Los ángulos son ilustrativos.',
'rotacion-bases':r'(a) Rotación de un triedro alrededor de su eje 1. (b) Representación de un vector fijo en la base inicial y la girada. Las líneas discontinuas identifican la orientación inicial y las continuas la girada; las proyecciones se leen respecto de sus ejes respectivos. La matriz de orientación y su transpuesta tienen funciones distintas.',
'derivada-director':r'Evolución espacial de un director de longitud constante. La cuerda une $\vct e_i(t)$ y $\vct e_i(t+\Delta t)$ y representa $\Delta\vct e_i$; la derivada en $t$ es tangente a la trayectoria circular y perpendicular al director. Las longitudes se amplían para mostrar su relación geométrica.',
'rotacion-deformacion':r'Una misma porción material en tres dimensiones: (a) referencia, (b) rotación rígida y (c) deformación por cortante. La cuadrícula identifica líneas materiales. La rotación conserva los ángulos y las longitudes; la deformación cambia la forma.',
'sistemas-lateral':r'Sistemas de referencia de la base, la góndola y el cubo en una vista espacial. $\vct c_B(t)$ sitúa la base respecto de $O_N$ y los triedros muestran sus tres direcciones. El superíndice $H,n$ identifica la base nominal del cubo. Los volúmenes y separaciones son esquemáticos; no representan una malla de sólidos.',
'cubo-nominal':r'Orientación nominal del cubo en tres dimensiones. El azimut $\psi$ gira las direcciones 2 y 3 alrededor del eje 1, que permanece común. Las direcciones inerciales son discontinuas y las nominales continuas. El superíndice $H,n$ equivale a la notación $\overline{\vct e}_i^H$ del texto.',
'marcos':r'Triedros de las tres raíces para azimut nominal nulo. El eje $\vct d_{1b}$ es longitudinal, $\vct d_{2b}$ tangencial y $\vct d_{3b}=\vct E_1$. Se muestran las tres direcciones, los puntos $P_b$ y el origen del cubo. Las separaciones angulares son $120^\circ$ y la perspectiva conserva la convención dextrógira.',
'palas-paso':r'Rotación de paso de una sección en tres dimensiones. Las direcciones discontinuas $\vct d_{ib}^{H}$ corresponden al montaje sin paso y las continuas $\vct d_{ib}^{H,p}$ a la sección rotada. El eje longitudinal permanece común y la raíz no se traslada. El espesor de la sección facilita la lectura de su orientación.',
'arbol':r'Jerarquía de los sistemas de referencia: newtoniano $N$, base $B$, góndola $G$, cubo $H$, raíz $P_b$ y sección $s$. Cada símbolo $\mathcal F$ identifica un triedro espacial. Las flechas indican relaciones cinemáticas y cambios de componentes; las ubicaciones son esquemáticas y no imponen conexiones rígidas.',
'cadena-posiciones':r'Composición de posiciones desde el origen newtoniano hasta una partícula de pala. Los puntos intermedios corresponden a la base, la góndola, el cubo y la raíz. La flecha directa representa la posición absoluta $\vct x_b$. El esquema espacial no está a escala.',
'tresniveles':r'Una misma porción de viga en (a) referencia material, (b) movimiento nominal y (c) configuración actual. El contorno discontinuo de (c) reproduce la configuración nominal; la diferencia se identifica mediante $\vct u$. Los pequeños triedros conservan la orientación inercial en los tres paneles.',
'particula-seccion':r'Posición de una partícula de viga. (a) Línea de referencia $\vct r(S,t)$, sección rígida y triedro de directores. (b) Ampliación de la sección: $\vct x_P=\vct r+\xi_2\vct d_2+\xi_3\vct d_3$. Se muestran los tres directores; $\vct d_1$ es normal a la sección. El volumen transparente representa la envolvente de la viga.',
'shear':r'Normal $\vct d_1$ a la sección y tangente $\vct t$ a la línea de referencia de una viga con cortante. El arco $\gamma$ mide el ángulo entre ambas direcciones en el esquema espacial. La rigidez de la sección no obliga a que su normal coincida con la tangente.',
'giro-perturbacion':r'Separación de la orientación inercial, la rotación nominal $\psi$ y una perturbación rotacional del cubo. El superíndice $H,n$ indica la base nominal y $H$ la perturbada. El incremento $\theta_{H1}$ se amplía para distinguir los triedros; la formulación emplea pequeñas perturbaciones.',
'suma-velocidades':r'Suma vectorial de los tres términos del teorema de transporte. Las flechas sucesivas representan la velocidad de traslación del origen, la contribución de la rotación de la base y la velocidad relativa transformada. La flecha directa cierra la suma y representa $\dd\vct x/\dd t$. Todas las contribuciones están expresadas en una base común.',
'centripeta':r'Movimiento circular de un punto fijo en la base nominal del rotor. La velocidad $\vct v$ es tangente a la trayectoria y perpendicular al radio $\vct r$; la aceleración centrípeta $\vct a$ apunta hacia el eje de giro. La flecha axial indica la dirección de la velocidad angular.',
'gravedad-giratoria':r'La misma gravedad inercial $\vct g$ observada con tres orientaciones nominales del cubo. El vector geométrico conserva su dirección, pero sus componentes en la base $H,n$ varían con el azimut. Los paneles presentan ángulos ilustrativos.',
'operacion':r'Separación geométrica entre referencia, configuración nominal y configuración actual con perturbación $\vct\eta$. El contorno discontinuo en (c) permite comparar el estado nominal con el actual. La figura ilustra una separación cinemática y no es una solución calculada de equilibrio ni una historia temporal.',
'centros':r'Sección con espesor ilustrativo y triedro completo: punto de referencia $O_s$, centro de área $C_A$ y centro de masa $C_m$. $\vct r_{cm}$ localiza el centro de masa respecto de $O_s$. Las posiciones se eligen para distinguir las definiciones; no corresponden a una sección medida.',
'masa-seccional':r'Geometría de la integración de masa en una sección. $\vct r$ sitúa el elemento $\dd m$ respecto de $O_s$ y $\vct r-\vct r_{cm}$ lo sitúa respecto del centro de masa $C_m$. El espesor de la superficie y el tamaño del elemento de masa son ilustrativos.',
'rigido-centro':r'Posiciones absolutas y relativas de una partícula de cuerpo rígido. Se cumple $\vct x_P=\vct x_O+\vct r=\vct x_C+\vct\rho$ y $\vct r=\vct c+\vct\rho$. La envolvente transparente sitúa el cuerpo y permite seguir los vectores desde el origen inercial $O_N$.',
'continuo-malla':r'Envolvente de una viga, línea material de referencia y nodos de una partición espacial. Los números siguen el orden material de los nodos. El movimiento de la sección señalada se recupera mediante las coordenadas nodales. La superficie es ilustrativa y no representa elementos sólidos.',
'coordenadas-nodo':r'Las seis coordenadas de un nodo se organizan por dirección: (a) $u_1,\theta_1$, (b) $u_2,\theta_2$ y (c) $u_3,\theta_3$. La flecha recta representa una traslación y el arco una rotación alrededor del eje correspondiente. Las amplitudes se amplían y no constituyen una respuesta simultánea calculada.',
'interpolacion-lineal':r'Interpolación de un campo de desplazamientos entre los valores nodales $\vct u_I$ y $\vct u_J$. Las flechas intermedias ilustran $\vct u(S)=N_I(S)\vct u_I+N_J(S)\vct u_J$. La línea curva y la envolvente son esquemáticas; las expresiones elementales cerradas del texto corresponden a segmentos rectos.',
'elemento':r'Orientación espacial de un elemento entre los nodos $I$ y $J$. El punto auxiliar $\vct X_a$ define una dirección transversal mediante su proyección $\vct p$ sobre el plano normal a $\vct e_1$. $\vct e_3$ es paralelo a $\vct p$ y $\vct e_2=\vct e_3\times\vct e_1$. El punto auxiliar no añade grados de libertad.',
'cubo-brazos':r'Brazos nominales $\vct r_{b0}^H$ desde el origen del cubo hasta las tres raíces $P_b$. Las líneas discontinuas distinguen estas relaciones geométricas de los volúmenes ilustrativos. Las separaciones son esquemáticas y no indican elementos flexibles adicionales.',
'vinculo-raiz':r'Compatibilidad incremental de una raíz: $\vct u_s=\vct u_H+\vct u_{rot}$, donde $\vct u_{rot}=\vct\theta_H\times\vct r$. La suma se representa mediante flechas consecutivas y la flecha directa cierra el desplazamiento total. El punto intermedio corresponde solamente a la traslación común del cubo.',
'conexion-elastica':r'Conexión elástica entre los sistemas de la góndola y el cubo. El resorte representa de forma simbólica los operadores generalizados de rigidez $K_d$ y disipación $C_d$. No implica un único grado de libertad ni fija la geometría de un cojinete comercial.',
'guia':r'Equilibrio relativo de un punto en una guía giratoria. La distancia radial constante es compatible con velocidad tangencial y aceleración centrípeta en el sistema inercial. La trayectoria discontinua y la guía con espesor distinguen el movimiento absoluto de la coordenada relativa.',
'acoplamiento-giroscopico':r'Representación geométrica de una contribución giroscópica antisimétrica. Los vectores $\dot{\vct q}$ y $G\dot{\vct q}$ son ortogonales, de modo que $\dot{\vct q}^{\tr}G\dot{\vct q}=0$. El triedro identifica coordenadas del espacio de perturbaciones; el dibujo ilustra esta identidad y no una forma modal calculada.',
'carga-seccion':r'Transporte de una resultante de sección: (a) fuerza y momento aplicados en un punto $A$ y (b) representación equivalente respecto de $O_s$. La fuerza se conserva y el momento cambia según $\vct m_{O_s}=\vct m_A+\vct r_A\times\vct f$. Los arcos señalan la dirección de los momentos; sus radios son ilustrativos.'}
BODY_ES=r'Vista tridimensional del aerogenerador y su idealización estructural. Las líneas y los nodos interiores corresponden a las vigas del modelo existente; las envolventes de torre, palas, góndola y cubo facilitan su identificación. Los perfiles de pala y las carcasas son ilustrativos: no proceden de un modelo CAD ni de una discretización de sólidos. Se conservan las coordenadas nodales y la conectividad del modelo.'
BODY_EN='Three-dimensional view of the wind turbine and its structural idealization. Interior lines and nodes represent the existing beam model. Tower, blade, nacelle and hub envelopes aid identification. Blade profiles and housings are illustrative; they are not CAD geometry or a solid discretization. Nodal coordinates and beam connectivity are preserved.'


def caption_start(block):return re.search(r'\\caption(?:\[[^\]]*\])?\{',block).start()
def figures(s,mapper,caps=None):
    def one(m):
        b=m.group();lm=re.search(r'\\label\{fig:([^}]+)\}',b)
        if not lm:return b
        key=lm.group(1)
        if key not in mapper:return b
        tail=b[caption_start(b):]
        if caps and key in caps:
            short=re.search(r'\\caption\[([^\]]+)\]',tail);brief='['+short.group(1)+']' if short else ''
            tail='\\caption'+brief+'{'+caps[key]+'}\\label{fig:'+key+'}\n\\end{figure}'
        return '\\begin{figure}[htbp]\n\\centering\n'+mapper[key]+'\n'+tail
    return re.sub(r'\\begin\{figure\}.*?\\end\{figure\}',one,s,flags=re.S)

def install(src,dest,name=None):
    dest.mkdir(parents=True,exist_ok=True);shutil.copy2(HERE/'figures'/f'{src}.pdf',dest/f'{name or src}.pdf')
def graphic(key,height='.40'):
    return r'\includegraphics[width=.96\linewidth,height='+height+r'\textheight,keepaspectratio]{figures/tecplot/'+key+'.pdf}'

def thesis():
    p=THESIS/'tesis_autocontenida.tex';s=p.read_text();mapping={k:graphic('concept_'+k) for k in CAPTIONS};mapping['turbina']=graphic('turbina_3d','.50')
    s=figures(s,mapping,{**CAPTIONS,'turbina':BODY_ES})
    # Delete obsolete drawing packages and colored drawing styles.
    s=s.replace('graphicx,tikz,booktabs','graphicx,booktabs')
    s=re.sub(r'\\usetikzlibrary\{[^}]+\}\n','',s)
    s=re.sub(r'\\definecolor\{(?:marcofijo|marcogiro|perturbacion|inercial|solidario|seccion)\}[^\n]*\n','',s)
    if '\\tikzset{\n tesisgrafico' in s:
        a=s.index('\\tikzset{\n tesisgrafico');b=s.index('\\usepackage{microtype',a);s=s[:a]+s[b:]
    s=re.sub(r'\\tikzset\{>=Latex[^\n]*\n','',s)
    s=s.replace('urlcolor=blue','urlcolor=black')
    s=s.replace('presenta cada rotación elemental en el plano perpendicular a su eje','presenta cada rotación elemental mediante el triedro completo y el arco en el plano perpendicular a su eje')
    s=s.replace(r'Una barra superior identifica la base nominal. El símbolo $\odot$ señala un eje dirigido hacia el observador y $\otimes$ uno dirigido hacia el plano del dibujo.',r'El superíndice $H,n$ identifica la base nominal del cubo en las figuras. Las tres direcciones de cada triedro se muestran mediante flechas espaciales; las líneas discontinuas permiten distinguir la orientación inercial de la nominal.')
    s=s.replace('muestra la guía en dos orientaciones:','muestra la guía y la trayectoria circular en una vista espacial:')
    extra=r'''
\begin{figure}[htbp]
\centering
\includegraphics[width=.94\linewidth,height=.38\textheight,keepaspectratio]{figures/tecplot/turbina_conexiones_3d.pdf}
\caption[Conexiones interiores del rotor]{Detalle espacial de los elementos unidimensionales dentro de la envolvente del rotor. Se identifican los nodos de góndola 129, cubo 130 y raíces 21, 57 y 93. Las relaciones de raíz se imponen mediante compatibilidad cinemática; las envolventes son ilustrativas.}
\label{fig:conexiones3d}
\end{figure}
'''
    if 'fig:conexiones3d' not in s:s=s.replace('\\label{fig:turbina}\n\\end{figure}','\\label{fig:turbina}\n\\end{figure}\n'+extra)
    scope=r'''
\chapter*{Alcance de las ilustraciones}\addcontentsline{toc}{chapter}{Alcance de las ilustraciones}
Los esquemas cinemáticos son representaciones espaciales originales en escala de grises. Los volúmenes, las separaciones y las amplitudes permiten leer las relaciones mecánicas; no constituyen resultados de simulación. Su composición toma como referencia el uso de envolventes, líneas de referencia y directores en Wasmer y Betsch \cite{wasmer2024}, conservando aquí el director 1 como dirección longitudinal. Las figuras no contienen títulos ni pies incorporados: su definición y procedencia se indican en el texto y en cada descripción.

Las vistas del aerogenerador utilizan las coordenadas y la conectividad de vigas existentes. Las superficies de pala, las carcasas y los detalles exteriores son envolventes ilustrativas; no se dispone de la geometría CAD ni de perfiles aerodinámicos suficientes para reproducir una turbina comercial específica. La malla estructural continúa siendo unidimensional. Esta revisión gráfica conserva la formulación y los resultados almacenados.
'''
    if '\\chapter*{Alcance de las ilustraciones}' not in s:s=s.replace('\\tableofcontents',scope+'\n\\tableofcontents',1)
    bib=r'\bibitem{wasmer2024} Wasmer, P. y Betsch, P. (2024). A projection-based quaternion discretization of the geometrically exact beam model. \emph{International Journal for Numerical Methods in Engineering}, 125(20), e7538. \url{https://doi.org/10.1002/nme.7538}.'
    if '\\bibitem{wasmer2024}' not in s:s=s.replace('\\end{thebibliography}',bib+'\n\\end{thebibliography}')
    p.write_text(s)
    for key in list(mapping.values()):pass
    for k in CAPTIONS:install('concept_'+k,THESIS/'figures/tecplot')
    for k in ['turbina_3d','turbina_conexiones_3d']:install(k,THESIS/'figures/tecplot')
    # Synchronize the modular manuscript with the current expanded source.
    starts=list(re.finditer(r'\\chapter\{',s));tail=s.index('\\begin{thebibliography}')
    names=['00_introduccion','01_problema','02_cinematica','03_propiedades','04_elementos','05_operacion','06_notacion'];assert len(starts)==7
    for j,(m,name) in enumerate(zip(starts,names)):
        end=starts[j+1].start() if j+1<len(starts) else tail
        (THESIS/'capitulos'/f'{name}.tex').write_text(s[m.start():end])
    main=s[:starts[0].start()]+'\n'.join('\\input{capitulos/'+n+'}' for n in names)+'\n'+s[tail:]
    (THESIS/'tesis_modelo.tex').write_text(main)
    return [str(p),str(THESIS/'tesis_modelo.tex')]

def formulation():
    out=[];d=ROOT/'docs/formulacion_revista_20260919'
    from reconcile_paper import install_figures
    install_figures(d)
    out.extend(str(d/f'FCEFyN_{lang}.tex') for lang in ['ES','EN'])
    d=ROOT/'docs/formulacion_matematica_20260919';p=d/'FORMULACION_MATEMATICA.tex';s=p.read_text();s=figures(s,{'modelo':r'\includegraphics[width=.83\textwidth,height=.42\textheight,keepaspectratio]{modelo.pdf}'},{'modelo':BODY_ES});p.write_text(s);install('turbina_3d',d,'modelo');out.append(str(p))
    return out

if __name__=='__main__':dump(HERE/'reports/updated_documents.json',thesis()+formulation())

def panels(keys,columns=1):
    rows=[]
    for j in range(0,len(keys),columns):
        rows.append('\\hfill\n'.join(r'\begin{minipage}{'+str(.96/columns)+r'\linewidth}\centering\includegraphics[width=\linewidth]{figures/tecplot/'+k+r'.pdf}\end{minipage}' for k in keys[j:j+columns]))
    return '\n\\par\\medskip\n'.join(rows)

def sensitivity_documents():
    d=ROOT/'docs/sensibilidad_morris_20261006';p=d/'SECCION_MORRIS_REVISION.tex';s=p.read_text()
    keys={'proceso':['morris_proceso'],'trayectoria':['morris_trayectoria','morris_trayectoria_factores'],'sentidos':['morris_sentidos'],'participaciones':['morris_participaciones'],'dominio':['morris_dominio'],'ruido':['morris_ruido'],'convergencia':['morris_convergencia'],'dispersion':['morris_dispersion']}
    caps={
    'proceso':r'Flujo del posprocesamiento de sensibilidad: dominio exploratorio, trayectorias, casos almacenados, seguimiento, efectos frente al ruido y aceptación. Cada caso es un equilibrio independiente a azimut congelado; la sensibilidad total incluye el cambio del equilibrio y de los operadores. El giro se prescribe alrededor del eje 129--130, sin guiñada nominal.',
    'trayectoria':r'Primera trayectoria ejecutada: (a) recorrido espacial en los tres factores y (b) valores por vértice en su orden de evaluación. Cada arista modifica un solo factor. Los segmentos unen casos almacenados y no describen una evolución temporal del rotor.',
    'sentidos':r'Secantes normalizadas con signo, $\overline c_i=\mu_i/0.20$. Los índices 1--7 corresponden a 1+2, 3, 4+5, 6+7, 8+9, 10+11 y 12. Los marcadores llenos identifican medias aceptadas y los vacíos medias no resueltas. El grupo 12 se conserva en la organización del dominio, pero está excluido del cálculo de estimadores.',
    'dominio':r'Dieciséis combinaciones evaluadas a velocidad fija de 12.4 rpm. Cada punto y su etiqueta corresponden a una frecuencia media del grupo 10+11 almacenada. No se interpolan frecuencias entre puntos. Aumentar masa/inercia y aumentar rigidez producen efectos opuestos; la compensación diagonal es parcial.',
    'convergencia':r'Estabilización de estimadores de los grupos 6+7 y 10+11 con prefijos de 10, 20 y 40 trayectorias del mismo diseño. Los símbolos distinguen factores y la leyenda identifica cada grupo. Las líneas unen prefijos calculados y no prueban convergencia asintótica.',
    'ruido':r'Influencia frente a la envolvente empírica de ruido, en escala logarítmica. Se conserva el orden de grupos de la figura de secantes; la línea horizontal indica el umbral de aceptación 10. Los marcadores vacíos permanecen no resueltos. La estabilización de una media no basta para aceptarla.'}
    caps['trayectoria']=r'Primera trayectoria ejecutada en los tres factores del diseño. Cada arista modifica un solo factor. Los segmentos unen casos almacenados y no describen una evolución temporal del rotor.'
    s=figures(s,{k:graphic(v[0]) if k=='trayectoria' else panels(v) if len(v)>1 else graphic(v[0]) for k,v in keys.items()},caps)
    if 'fig:trayectoria-factores' not in s:
        suffix='\\begin{figure}[htbp]\\centering\n'+graphic('morris_trayectoria_factores')+'\n'+r'\caption{Factores por vértice de la primera trayectoria, en su orden de evaluación. Los símbolos identifican masa/inercia de palas, rigidez y velocidad. El eje horizontal indica vértices del diseño, no tiempo físico.}\label{fig:trayectoria-factores}\end{figure}'
        s=re.sub(r'(\\label\{fig:trayectoria\}\s*\\end\{figure\})',lambda m:m.group()+'\n'+suffix,s)
    s=s.replace(r'\usepackage{tikz,pgfplots}',r'\usepackage{graphicx}');s=re.sub(r'\\pgfplotsset[^\n]*\n|\\usetikzlibrary[^\n]*\n|\\definecolor[^\n]*\n','',s)
    s=s.replace('Una barra negativa','Un punto de ordenada negativa').replace('las barras','los marcadores').replace('las celdas coloreadas','los puntos').replace('barras','marcadores')
    s=s.replace('Todas las figuras son vectoriales y sus datos están incorporados en esta misma fuente.', 'Las figuras se exportan desde Tecplot y se incluyen como PDF externos. Los datos, macros y paquetes nativos se conservan en la biblioteca de posprocesamiento del proyecto.')
    p.write_text(s)
    for a in set(k for vv in keys.values() for k in vv):install(a,d/'figures/tecplot')
    body=s.split(r'\maketitle',1)[1].split(r'\begin{thebibliography}',1)[0]
    (d/'seccion_para_incorporar.tex').write_text('% Versión equivalente del cuerpo ilustrado. Requiere graphicx, los PDF de figures/tecplot y la referencia morris1991.\n'+body)
    # Retain the historical generator, and point regeneration to the new workflow.
    legacy=d/'revision_reunion/expand_document.py';archive=HERE/'archive/morris_expand_document_before_tecplot.py'
    if not archive.exists():shutil.copy2(legacy,archive)
    legacy.write_text('"""Synchronize the Tecplot version; the former inline generator is archived."""\nimport runpy, sys\nfrom pathlib import Path\np=Path(__file__).resolve().parents[3]/"postprocessing/tecplot_20261007/scripts/integrate_documents.py"\nsys.path.insert(0,str(p.parent))\nm=runpy.run_path(str(p));m["sensitivity_documents"]()\n')
    local=ROOT/'docs/sensibilidad_20261005';lp=local/'SECCION_SENSIBILIDAD_REVISION.tex';text=lp.read_text().replace(r'\usepackage{amsmath,amssymb,booktabs,array}',r'\usepackage{amsmath,amssymb,booktabs,array,graphicx}')
    if 'fig:local-tecplot' not in text:
        fig=r'''\begin{figure}[htbp]\centering
\includegraphics[width=.95\linewidth]{figures/tecplot/local_signos.pdf}
\caption{Indicadores locales de frecuencia que superan conjuntamente los controles de señal, seguimiento y estabilización del paso. El índice identifica el grupo según el orden de la tabla de resultados. Los indicadores no resueltos se conservan en los resultados y en el archivo de estados del posprocesamiento; su ausencia en este panel no significa sensibilidad nula.}\label{fig:local-tecplot}
\end{figure}
'''
        text=text.replace(r'\subsection{Respuesta temporal e interacciones}',fig+'\n'+r'\subsection{Respuesta temporal e interacciones}')
    text=re.sub(r'\\caption\{[^\n]*\}\\label\{fig:local-tecplot\}',lambda m:r'\caption{Secantes locales de frecuencia para el paso relativo 0.01. Los índices 1--4 corresponden a los grupos 1+2, 6+7, 8+9 y 10+11. Los marcadores llenos superan conjuntamente los controles de señal, seguimiento y estabilización; los vacíos conservan candidatos no resueltos y no deben interpretarse como efectos físicos aceptados. El pequeño desplazamiento horizontal separa parámetros dentro de cada grupo.}\label{fig:local-tecplot}',text)
    lp.write_text(text);install('local_signos',local/'figures/tecplot')
    (local/'seccion_para_incorporar.tex').write_text('% Requiere graphicx y los PDF de figures/tecplot.\n'+text.split(r'\maketitle',1)[1].split(r'\begin{thebibliography}',1)[0])
    return [str(p),str(lp)]

def integrated():
    d=ROOT/'docs/manuscrito_integrado_20260919';p=d/'MANUSCRITO_INTEGRADO.tex';s=p.read_text()
    replacement={'modelo':['turbina_3d'],'rigidos_malla':['nucleo_rigido','refinamiento'],'teorias':['teoria_diferencia','teoria_convergencia'],'rom_historias':['rom_historia_0','rom_historia_2','rom_historia_5','rom_historia_7'],'rom_precision_coste':['rom_error','rom_aceleracion','rom_operatorAndBasisBytes','rom_massParticipationXPercent']}
    def one(m):
        key,width,cap,label=m.groups()
        if key not in replacement:return m.group()
        if key=='modelo':cap=BODY_ES
        if key=='rom_precision_coste':cap=cap.replace(' La línea del 1\\% es un objetivo comparativo, no reglamentario.','')
        if key=='rigidos_malla':cap=cap.replace('El cero de la referencia no se representa en escala logarítmica.','El cero de la referencia se conserva en los datos y se omite en la escala logarítmica vertical.')
        plots=panels(replacement[key]) if len(replacement[key])>1 else graphic(replacement[key][0],'.43')
        return '\\begin{figure}[htbp]\\centering\n'+plots+'\n\\caption{'+cap+'}\\label{'+label+'}\n\\end{figure}'
    # Caption braces may nest; match each line, then parse its four balanced arguments.
    def parse_line(line):
        if not line.startswith(r'\figura{'):return line
        pos=len(r'\figura');args=[]
        for _ in range(4):
            assert line[pos]=='{';start=pos+1;depth=1;pos+=1
            while depth:
                if line[pos]=='{':depth+=1
                elif line[pos]=='}':depth-=1
                pos+=1
            args.append(line[start:pos-1])
        if args[0] not in replacement:return line
        class Match:
            def groups(self):return args
            def group(self):return line
        return one(Match())
    s='\n'.join(parse_line(l) for l in s.splitlines())+'\n';p.write_text(s)
    # Keep plotted annotations readable: two full-width plots per float. Four
    # plots are divided into two consecutive figures rather than shrunk.
    labelkeys={'geometria':'modelo','rigidosmalla':'rigidos_malla','teorias':'teorias','romhistorias':'rom_historias','romcoste':'rom_precision_coste'}
    def reflow(m):
        block=m.group();label=re.search(r'\\label\{fig:([^}]+)\}',block)
        if not label or label.group(1) not in labelkeys:return block
        key=labelkeys[label.group(1)];plots=replacement[key]
        cap=block[caption_start(block):].split('\\label{',1)[0].strip()
        if len(plots)<=2:return '\\begin{figure}[htbp]\\centering\n'+(panels(plots) if len(plots)>1 else graphic(plots[0],'.43'))+'\n'+cap+'\\label{fig:'+label.group(1)+'}\\end{figure}'
        continuations={'rom_historias':r'Respuesta estacionaria de ocho segundos: (a) aceleración absoluta global X de la góndola y (b) momento basal global Y. Se conservan las historias almacenadas del MHT y los ROM seleccionados.', 'rom_precision_coste':r'Costo y participación de los ROM estacionarios: (a) almacenamiento de operadores y base y (b) participación de la carga inercial global X. Se conservan los datos históricos y sus definiciones; el almacenamiento no es memoria pico.'}
        primary={'rom_historias':r'Respuesta estacionaria de ocho segundos: (a) desplazamiento global X de la góndola y (b) de la punta de pala 1. Las curvas son las historias almacenadas del MHT y los ROM seleccionados; su proximidad visual no sustituye los errores de la tabla.', 'rom_precision_coste':r'Precisión y eficiencia de los ROM estacionarios: (a) máximo error de historia de cada salida y (b) aceleración de integración y de un caso incluyendo base y proyección. Los símbolos distinguen curvas en escala de grises.'}
        return '\\begin{figure}[htbp]\\centering\n'+panels(plots[:2])+'\n\\caption{'+primary[key]+'}\\label{fig:'+label.group(1)+'}\\end{figure}\n\\begin{figure}[htbp]\\centering\n'+panels(plots[2:])+'\n\\caption{'+continuations[key]+'}\\label{fig:'+label.group(1)+'-continuacion}\\end{figure}'
    # Existing continuations are retained on subsequent synchronization runs.
    if 'fig:romhistorias-continuacion' not in s:s=re.sub(r'\\begin\{figure\}.*?\\end\{figure\}',reflow,s,flags=re.S)
    else:
        s=figures(s,{k:graphic('turbina_3d','.43') if k=='geometria' else panels(replacement[labelkeys[k]]) for k in ['geometria','rigidosmalla','teorias']})
    p.write_text(s)
    for vv in replacement.values():
        for k in vv:install(k,d/'figures/tecplot')
    restore_operating(d);restore_appendices(d)
    return [str(p)]

def restore_operating(d):
    j=json.loads((d/'evidence/operating_results.json').read_text());m=j['modal'];eq=j['equilibrium']['points'];checks=j['modalGates']['metrics']
    def f(x):return f'{x:.6g}'
    rows='\n'.join(f'{int(b)} & {m["dampedFrequency_Hz"][0][i]:.6f} & {m["dampedFrequency_Hz"][-1][i]:.6f} \\\\' for i,b in enumerate(m['branchIds']))
    text=r'''% Restored from the persisted operating_results.json; no new solver calls.
\subsection{Equilibrio y espectro del estado operativo}
El barrido corregido contiene nueve velocidades entre 0 y 12 rpm y doce ramas seguidas. Se emplean los resultados almacenados de la revisión energética de septiembre, con gravedad y operadores congelados en el azimut de referencia. Este análisis no representa una órbita periódica ni un problema de Floquet.
'''
    text+=f'La máxima traslación nodal del equilibrio pasa de {f(eq[0]["maxNodalTranslationNorm_m"])} m a {f(eq[-1]["maxNodalTranslationNorm_m"])} m entre los extremos del barrido. El máximo residuo QEP normalizado almacenado es {f(checks["maximumQepResidual"])} y el mínimo MAC efectivo es {f(checks["minimumEffectiveTrackingMAC"])}. Las multiplicidades se controlan mediante subespacios.\n'
    text+=r'\begin{table}[htbp]\centering\small\caption{Frecuencias amortiguadas de las ramas seguidas en los extremos del barrido corregido.}\begin{tabular}{rrr}\toprule Rama & 0 rpm [Hz] & 12 rpm [Hz]\\\midrule'+'\n'+rows+r'\bottomrule\end{tabular}\end{table}'+'\n'
    for keys,caption,label in [(['campbell','seguimiento_ramas'],'(a) Frecuencias amortiguadas del sistema congelado y (b) calidad efectiva del seguimiento por formas. Las líneas unen las velocidades calculadas; no constituyen modos de Floquet.','fig:campbell-tecplot'),(['equilibrio_velocidad'],'Máxima norma de traslación nodal del equilibrio guardado frente a velocidad. Las líneas unen los estados almacenados.','fig:equilibrio-tecplot'),(['sismo_n129_ux','sismo_n56_ux'],'Perturbaciones de desplazamiento global X de (a) góndola, nodo 129, y (b) punta de pala 1, nodo 56, en los casos almacenados de 0 y 12 rpm. La ventana y el procesamiento corresponden al benchmark guardado; no se presenta un registro experimental adicional.','fig:sismo-tecplot'),(['sismo_convergencia'],'Comparación temporal del desplazamiento global Y del nodo 129 para los cinco pasos almacenados. Se conserva la ventana de un segundo y la recuperación local de perturbaciones.','fig:sismo-convergencia-tecplot')]:
        text+='\\begin{figure}[htbp]\\centering\n'+(panels(keys) if len(keys)>1 else graphic(keys[0]))+'\n\\caption{'+caption+'}\\label{'+label+'}\n\\end{figure}\n'
        for k in keys:install(k,d/'figures/tecplot')
    text+=r'Las matrices y la reconstrucción física corresponden al mismo instante operativo. Las diferencias entre estados de giro incluyen equilibrio, transporte, restricciones temporales y transformación de coordenadas. No se atribuye el cambio de respuesta a un único bloque giroscópico aislado.'+'\n'
    (d/'resultados_operativos.tex').write_text(text)

def restore_appendices(d):
    # The integrated manuscript uses the earlier notation and equation labels.
    # Keep its established appendix source separate from the expanded article.
    import zipfile
    with zipfile.ZipFile(HERE/'archive/editorial_before_tecplot.zip') as z:
        source=z.read('solver/docs/formulacion_revista_20260919/cuerpo_es.tex').decode()
    def section(start,end):return source.split(start,1)[1].split(end,1)[0]
    elem=section(r'\section{Apéndice A. Operadores elementales}',r'\section{Apéndice B.')
    gyro=section(r'\section{Derivación energética de los términos de giro}',r'\section{Equilibrio y tangente estructural}')
    maps=section(r'\subsection{Coordenadas multiblade}',r'\section{Amortiguamiento y acciones externas}')+section(r'\section{Apéndice C. Operadores temporales}',r'\section{Declaración sobre uso de inteligencia artificial}')
    solution=section(r'\subsection{Integración y recuperación física}',r'\section{Alcance y conclusiones}')
    solution=solution.replace(r'de la ec.~\eqref{eq:fullsystem},','del sistema físico,')
    # Avoid dangling references to article-only equations. The identities copied
    # here are unchanged; the main manuscript retains its existing notation.
    mapping={'eq:Ms':'eq:masa6','eq:dynamicprojection':'eq:mpc','eq:T2':'eq:energia2','eq:fullsystem':'eq:sismo'}
    assembled=''
    for title,label,body in [('Operadores elementales','ap:elemento',elem),('Matrices energéticas del giro','ap:gyro',gyro),('Mapas temporales y transformación multiblade','ap:mapas',maps),('Integración y recuperación','ap:solucion',solution)]:
        for old,new in mapping.items():body=body.replace('\\eqref{'+old+'}','\\eqref{'+new+'}')
        body=re.sub(r'\\label\{(eq:[^}]+)\}',lambda m:'\\label{apx:'+m.group(1)+'}',body)
        local=re.findall(r'\\label\{apx:(eq:[^}]+)\}',body)
        for key in local:body=body.replace('\\eqref{'+key+'}','\\eqref{apx:'+key+'}')
        assembled+='\\section{'+title+'}\\label{'+label+'}\n'+body+'\n'
    assembled+=r'''\section{Fuentes, unidades y trazabilidad}\label{ap:datos}
La geometría conserva 138 nodos y 133 elementos de viga. Se eliminan de esta visualización únicamente los cuatro elementos heredados de penalización tipo 3, sustituidos en el modelo vigente por restricciones exactas. Las coordenadas se expresan en metros y cada nodo conserva el orden $[u_x,u_y,u_z,\theta_x,\theta_y,\theta_z]$.

Los resultados operativos proceden de las campañas corregidas de septiembre y se extraen del archivo de evidencia de este manuscrito. Las comparaciones ROM y de refinamiento son estacionarias e históricas. La biblioteca Tecplot conserva la relación por figura entre fuentes, unidades, configuración, dataset, macro, layout y paquete nativo. No se lanzaron campañas para completar las figuras.

Las envolventes de la turbina tienen una finalidad ilustrativa. La formulación y la malla computacional siguen siendo de vigas; las superficies no incorporan rigideces, masas ni grados de libertad de sólidos. Para las formas complejas de la biblioteca se conservan ramas individuales, fases de $0^\circ$ y $90^\circ$, normalización por la máxima traslación nodal compleja y amplificación declarada. No se construye una forma modal a partir de la frecuencia media de un grupo.
'''
    (d/'apendices.tex').write_text('% Restored from the existing formulation article and persisted evidence.\n'+assembled)

def distribution():
    from reconcile_paper import synchronize
    synchronize()
    return [str(ROOT/'output/latex'/name/f'FCEFyN_{lang}.tex') for name in ['FCEFyN_Formulacion_Bilingue','FCEFyN_Overleaf'] for lang in ['ES','EN']]

# Run the extra project integrations when invoked, after the thesis/formulation
# block above. These functions are also exposed to the compatibility wrapper.
if __name__=='__main__':
    target=HERE/'reports/updated_documents.json';old=json.loads(target.read_text());dump(target,old+sensitivity_documents()+integrated()+distribution())
