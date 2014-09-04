# encoding: UTF-8

#------------------------------------------------------------------------------

# NOTE: This is a one-time rake task that will populate
# all existing houses with the Mare neighborhood.

namespace :documentation_sections do

  #----------------------------------------------------------------------------

  desc "Add Spanish Content to Manual"
  task :add_spanish_translation => :environment do


    ds = DocumentationSection.find_by_title("Como se cadastrar")
    ds.title_in_es = "Como registrarse"
    ds.content_in_es = "¡Crear su registro en Dengue Torpedo (DT) es fácil!
    Para iniciar el registro, la página inicial solicita que proporcione
    su Email, nombre, apellido, contraseña para accesar su cuenta (mínimo
    de 4 caractéres), y confirmación de contraseña.
    Para proseguir, haga clic en el botón de Regístrese. Usté será
    dirigido a la página de Configuraciones donde ustéd completará su registro
    añadiendo un poco más de información personal.
    ATENCIÓN: Usted debe escribir su nombre como consta en un documento
    válido (ej. credencial de elector) que será validado para
    intercambiar sus puntos por premios."
    ds.save(:validate => false)


    ds = DocumentationSection.find_by_title("Como completar sua conta")
    ds.title_in_es = "Como completar su cuenta"
    ds.content_in_es = "Los datos que usted proporcionó en la página inicial estarán
    pre-escritos en la página de Configuraciones. Añada usted los datos
    que falten para poder personalizar su cuenta.
    Los campos de información incluyen la identificación del jugador
    jugador, colonia, correo electrónico, número y tipo de cuenta de
    teléfono celular.
    Si usted se registró en el sitio porque un amigo o vecino lo invitó,
    no olvide mencionar a esa persona seleccionandola en el campo junto
    a la frase '¿Alguien lo invitó a registrarse en DT?'"
    ds.save(:validate => false)



    ds = DocumentationSection.find_by_title("Barra de navegação")
    ds.title_in_es = "Barra de navegación"
    ds.content_in_es = "En la barra superior de navegación usted encontrará los siguientes enlaces
    para accesar a cada
    página del sitio.

    * Mi perfíl
    * Mi comunidad
    * Equipos
    * Focos marcados

    La barra puede ser accesada en cualquier momento. Ahí aparecen todos
    los enlaces desde el momento en que usted entra en la página de DT.
    Una vez llevado a cabo su registro, entre en su cuenta en la página
    inicial escribiendo su correo electrónico (parte superior derecha de
    la página inicial). Una vez conectado en su cuenta, usted puede hacer
    cambios en sus datos personales, unirse o dejar equipos, etc.
    Para ello, haga clic en Configuraciones."
    ds.save(:validate => false)


    ds = DocumentationSection.find_by_title("O que é um foco?")
    ds.title_in_es = "¿Qué es un foco?"
    ds.content_in_es = "Un foco de infección, o simplemente foco, es un lugar con agua
    estancada, generalmente limpio, donde los mosquitos ponen sus huevos.
    Los focos se pueden clasificar como:

    * Focos activos: Contienen pupas o larvas de mosquito

    * Focos potenciales: Posibles criaderos sin pupas o larvas visibles.

    Una vez encontrados y reportados, los dos tipos de focos son llamados
    'Focos marcados' y les corresponde la misma puntuación. Es decir, en
    DT no hay distinción entre focos activos y potenciales."
    ds.save(:validate => false)


    ds = DocumentationSection.find_by_title("Como jogar")
    ds.title_in_es = "¿Como jugar?"
    ds.content_in_es = "Hay varias formas de jugar. Usted puede ganar puntos al:

    * Marcar focos;

    * Eliminar focos;

    * Publicar en el blog información relevante para la comunidad;

    * Invitar a amigos y vecinos a jugar;

    * Ganar puntos;

    * Intercambiar puntos por premios;

    * Participar en las atividades promovidas por Dengue Torpedo.

    Una vez conectado en su cuenta de DT, usted podrá visualizar los focos

    marcados. Hay dos tipos de focos marcados, abiertos y

    eliminados. Los focos que siguen abiertos pueden ser eliminados por

    cualquier jugador para ganar puntos.

    Visualización de focos de infección

    ------------------

    Al accesar la página que de los 'Focos Marcados' ustéd verá

    reportes de los focos abiertos y eliminados. La localizacón de los focos se

    mostrará en un mapa de su comunidad. Cada reporte tiene una

    dirección, fotos, descripción del tipo de foco con método de

    eliminación, y otros datos. Los focos abiertos poseen un contador que

    muestra el tiempo restante para eliminarlos.

    El mapa cuenta con una herramienta de acercamiento para

    visualizar mejor los focos. La lista de focos se ajusta de manera

    dinámica con el ajuste de enfoque en el mapa. Para

    disminuir la escala del mapa (acercarmiento), haga clic en el

    signo '+' y haga clic en el signo '-' para alejarse. La lista de

    focos también puede ajustarse arrastrando el mapa. Para arrastrar el

    mapa, coloque el cursor sobre el mapa, haga clic sin soltar con el

    botón derecho, y arrastre.

    La página 'Focos Marcados' tiene tres filtros para visualizar los

    focos: Todos, Abiertos, Eliminados. Haga clic en los páneles para

    visualizar los focos marcados por categoría.

    ¿Como marcar focos?

    --------------

    Usted puede marcar focos a través del sitio (www.denguetorpedo.com) o

    enviando un mensaje de texto (SMS) desde su celular.


    Como marcar un foco en el sitio de Dengue Torpedo

    ---------------------------

    Para marcar un foco, usted tiene que accesar a su cuenta y hacer clic

    en la frase 'Focos Marcados' en la barra de navegación. Al entrar en

    la página de los focos usted podrá visualizar una lista de los focos

    marcados en su región.

    Para marcar un foco, haga clic en el botón de 'Marcar un foco'. Usted

    será direccionado a una nueva página en la que podrá llenar los campos

    solicitados:

    1. Dirección del foco localizado. La dirección debe ser llenada en el

    formato solicitado para ser identificada en el mapa.

    2. Descripción del lugar. La descripción debe incluir detalles como

    'en la loza del patio', 'en la acera', etc.

    3. Cargue una imagen del foco encontrado. Haga clic en el botón de

    'Escoger archivo' o en 'Seleccionar una imagen del foco encontrado'.

    4. Seleccione un tipo de foco. Seleccione el tipo de foco encontrado

    de acuerdo con las opciones de la lista.

    5. Ajuste el marcador en el mapa. Puede que el sistema de mapeo no

    encuentre en el mapa. En ese caso, mueva el marcador haciendo clic en

    la localización correcta.

    Para finalizar esa etapa, haga clic en 'Enviar'. Usted será dirigido a

    la página 'Focos Marcados' donde va a ver su relato con toda la

    información que usted proporcionó. En caso de que usted tenga una

    cuenta en Facebook o Twitter, usted puede compartir el foco haciendo

    clic en el botón de 'Compartir' o 'Twitear'. Después de someter la

    información de su foco recibirá 50 puntos y la página mostrará un

    contador que comienza en 48 horas mostrando el tiempo restante antes

    de que el foco sea eliminado será mostrado.

    ATENCIÓN: En caso de que usted quera marcar un foco cuyo tipo

    no está en la lista de Tipos de foco, seleccione 'Otro tipo de

    foco'. Ustéd será dirigido a la página 'Contacto DT'. En ella,

    describa el Tipo de foco. Su propuesta será discutida con el equipo

    técnico del proyecto. De ser aprobada, el nuevo tipo de foco será

    incorporado en la lista, usted recibirá 100 puntos por la inovación y

    50 más por la identificación.



    Otras preguntas relativas a marcar o eliminar focos pueden ser

    esclarecidas leyendo el Manual de Conducta de Dengue Torpedo.




    Como marcar un foco por mensaje de texto

    -----------

    Para marcar un foco utilizando mensajes de texto (SMS) usted debe

    tomar una fotografía del foco y guárdela en su celular. Acto

    seguido, mande un mensaje de texto con la localización y descripción

    del foco encontrado a un número de Dengue Torpedo (##). Usted debe

    subir la fotografía del foco utilizando el sitio de Dengue Torpedo

    en cuanto tenga acceso a una computadora.

    Ej. Caja de agua descubierta en la calle Independencia #45

    Ej. Foco en plato pequeño de mazeta frente a la casa en el camino

    Emiliano Zapata # 150

    Después de enviar el SMS, usted va a recibir una de las siguientes

    notificaciones en su celular:

    - Si ya tiene una cuenta de Dengue Torpedo: '¡Enhorabuena! Su informe

    ha sido recibido'

    - Si aún no tiene una cuenta en Dengue Torpedo: 'Usted no tiene una

    cuenta. Regístrese en el sitio de Dengue Torpedo'

    - Si usted es un patrocinador o verificador registrado en Dengue

    Torpedo: 'Su perfil no está habilitado para envíos en Dengue Torpedo'

    Después de recibir el mensaje de éxito en su celular, usted debe

    accesar su cuenta de Dengue Torpedo desde una computadora y completar

    el marcado del foco en la página 'Focos Marcados'.

    El mensaje que ustéd envió por SMS aparecerá en la parte superior de

    la lista en la página de 'Focos Marcados'. Para completar el

    reporte, presione el botón verde 'Completar el foco'. Usted será

    direccionado a la página 'Completar el foco'. En esa página, usted

    debe llenar campos como los mencionados a continuación:

    1. Dirección del foco localizado. La dirección debe ser llenada en

    el formato solicitado para ser identificado en el mapa.

    2. Descripción del lugar. Ej. en la loza del

    patio, en la acera, etc

    3. Cargue una imagen del foco encontrado. Haga clic en el botón de

    'Escoja un archivo'

    4. Seleccione el tipo de foco de acuerdo con las opciones de la

    lista.

    5. Ajuste el marcador del mapa. Si no es posible encontrar su dirección

    en el mapa, mueva el marcador haciendo clic en la ubicación correcta.

    Después de finalizar los pasos anteriores, haga clic en

    'Enviar'. Usted será direccionado a la página 'Focos Marcados' donde

    usted verá su reporte con todas la información proporcionada.

    En caso de que usted tenga una cuenta de Facebook o Twitter, usted

    puede compartir el foco en su cuenta. Para eso, basta hacer clic en el

    botón 'Compartir o Twitear' y mostrarlo a todos sus amigos.

    Después de someter su foco, el contador aparece con 48 horas que

    representan el tiempo restante para que el foco sea eliminado. También

    en ese momento usted recibirá 50 puntos si completa un mensaje de

    texto en DT.


    Eliminando focos

    ----------------

    Para reportar un foco eliminado siga los siguientes pasos.

    1. Acesar a la página 'Focos Marcados'

    2. Encontrar el foco que usted eliminó en la lista de focos abiertos

    3. Cargar una foto del foco haciendo clic en el botón de 'Seleccione

    un archivo que contenga una imágen del foco eliminado'

    4. Después de finalizar los pasos anteriores, haga clic en 'Cargue'

    La foto del foco eliminado se eliminará y reaparecerá en la página

    'Focos Eliminados'.

    5. En caso usted tenha una cuenta en Facebook o Twitter, usted puede

    compartir el foco en su cuenta haciendo click en el botón de

    'Compartir o twitear con tus amigos'

    Cuando haya finalizado sus puntos serán sumados automáticamente y

    usted podrá verificar su puntuación accesando a la página 'Mi perfil'

    ATENCIÓN: En caso de que usted tenga una propuesta para otro método

    de eliminación que no esté en la lista de métodos de DT, seleccione

    'Otro método'. Su propuesta será discutida con el equipo técnico del

    proyecto. Si es aprobada, será incorporada en la lista de Métodos de

    eliminación compo puntuación. Usted recibirá al momento

    una propuesta de eliminación de enfoque. En el caso de que

    sea aprobada la propuesta, usted recibirá 100 puntos por la

    inovación.

    Otras preguntas relativas a como marcar y eliminar focos pueden ser

    exclarecidas leyendo el Manual de Conducta de Dengue Torpedo.

    Reglas del juego y verificación

    ----------------------------

    Como todo juego, Dengue Torpedo también tiene sus reglas. Algunas de

    las reglas más importantes son:

    Un jugador debe seleccionar

    1. El jugador debe seleccionar el Tipo de Foco de la lista de acuerdo

    con el tipo de foco que encontró. En caso que no

    correspondan el tipo seleccionado y el tipo encontrado, el jugador

    no recibirá los 50 puntos por marcar el foco.

    2. El jugador debe seleccionar de la lista de 'Método de eliminación' el

    método que corresponde al tipo de foco seleccionado. Si el método no

    corresponde con el tipo de foco, el jugador no recibirá los puntos por

    la eliminación.

    3. Después de marcado, el foco debe ser eliminado dentro de las

    siguientes 48 horas, conforme al contador de cada foco marcado pero no

    eliminado abierto. Después de las 48 horas, el tiempo expira y no será

    posible eliminar el foco para obtener puntos en DT.

    4. Para ganar 1 DT Torpedo, el jugador debe enviar un SMS con la

    información del foco y completar el reporte en el sitio de Dengue

    Torpedo. Para más información, consulte 'Marcando un foco por SMS'.

    Los focos marcados o eliminados en Dengue Torpedo son constantemente

    verificados por el equipo de juego y también por los verificadores,

    que son los Agentes Comunitarios de Salud y los Agentes de Vigilancia

    de Salud.

    Si hay una palomita (símbolo verde √) en el reporte del foco, el foco

    fue verificado y confirmado. En caso de que su relato de foco tenga

    una cruz (o tache, X), entonces hubo un problema con su reporte. En

    esos casos, debe contactar al equipo de Dengue Torpedo usando el

    enlace 'Contacto DT' (http://www.denguetorpedo.com/feedbacks/new).


    Microblog

    ---------

    Una de las herramientas de Dengue Torpedo es el microblog asociado al

    perfil de cada participante. Esos microblogs crean una red social de

    Dengue Torpedo. El microblog es su espacio de comunicación dentro

    de Dengue Torpedo. Con el microblog usted puede comunicarse con sus

    vecinos para realizar acciones conjuntas en su colonia, tales como

    jornadas vecinales de vigilancia y limpieza para eliminar brotes

    potenciales de dengue. Para publicar un microblog, basta ir a su perfil,
    teclear un título y

    escribir su idea."
    ds.save(:validate => false)



    ds = DocumentationSection.find_by_title("Como ganhar")
    ds.title_in_es = "¿Cómo ganar?"
    ds.content_in_es = %Q(Puntos

    En Dengue Torpedo cada jugador gana puntos de acuerdo con sus acciones

    de combate al dengue. Por ejemplo,

    Marcar un foco: 50 puntos.

    Eliminar un foco: 50 a 450 puntos de acuerdo con el método de

    eliminación del foco.

    Publicar en el miniblog: 5 puntos con un máximo de 100 pontos por o 20
    publicaciones.

    Reclutar un jugador: 50 puntos.

    Para saber cuantos puntos ustéd gana eliminando diferentes tipos de

    foco, consulte la lista siguiente:

    Tipo de Foco: Plato pequeño de mazeta

    Método de eliminación

    - Eliminación haciendo agujeros en el plato. 200 pontos

    - Plato removido. 200 puntos

    - Colocación de arena. 100 puntos

    - Retirado de agua y lavado para remover posibles huevecillos (una vez

    por semana). 50 puntos

    Tipo de foco: Llanta

    Método de eliminación:

    - Remoción y desecho de la llanta (entregado al servicio de

    limpieza). 50 puntos.

    - Arreglar para darle uso alternativo a la llanta: llenado con tierra

    para hacer una hortaliza o jardinera, llenado con arena, tierra, o

    cemento y utilización como piso. 450 puntos

    - Transferir la llanta sin agua y sin desechos a un local cubierto y

    seco. 100 puntos

    - Cubra la llanta con algo que para que no se transforme en un foco

    potencial de mosquito. 100 puntos.

    Tipo de Foco: Recipientes no utilizables y basura

    Método de eliminación:

    - Enjuague y guardado en almacén bien tapado. 0 puntos

    - Organice una jornada vecinal de limpieza en lugares donde no tengan

    acceso los servicios de limpieza locales (coordinada por los Agentes

    de Vigilancia Sanitaria). 450 puntos

    - Participe en una jornada vecinal de limpieza en lugares donde no tengan

    acceso los servicios de limpieza locales (coordinada por los Agentes

    de Vigilancia Sanitaria). 350 puntos

    Tipo de Foco: Pequeños recipientes utilizables, garrafas de vidrio,

    vasos, baldes, tinas de agua, etc.

    Método de eliminación:

    - Remueva el agua y friegue una vez por semana. En caso de bebederos

    de animales y aves, cambiar el agua y limpiar diariamente. 50 puntos.

    - Girar el recipiente para tirar sus contenidos. Secar y almacenar. 50
    puntos


    Tipo de Foco: Grandes recipientes utilizables, toneles, otros

    depósitos de agua, piletas, galones.

    Método de eliminación:

    - Cubrir de la caida de agua. 450 puntos

    - Tapar o cancelar automáticamente con una tapa o capota

    apropiada. 200 puntos

    - Otros recipientes: Lave, seque, cubra. 350 puntos.

    Tipo de Foco: Caño

    Método de eliminación:

    - Destapar y limpiar. 150 puntos

    Tipo de Foco: Registros abiertos

    Método de eliminación:

    - Selle con una cobertura impermeable para prevenir la penetración de

    agua sin perder acceso al registro. 300 puntos

    - Llenado con arena o tierra y cambio del registro o acceso a

    válvula a otro lugar. 300 puntos

    - Llenado con arena o tierra y cancelación del registro. 300 puntos

    Tipo de Foco: Charcos u otras acumulaciones de agua

    Método de eliminación:

    - Limpiado. 50 puntos.

    Tipo de Foco: Piscinas

    Método de eliminación:

    - Piscinas en uso: Limpie y talle una vez por semana. 350 puntos

    - Piscinas que no están en uso: Limpie, talle, y deshágace del

    agua. Si la piscina es de plástico, desmonte y guarde. 350 puntos.

    Tipo de Foco: Pozas de agua estancada

    Método de eliminación:

    - Elimine el agua y remueva la basura. 50 puntos

    Tipo de Foco: Pozas de agua estancada

    Método de eliminación:

    - Enguague con agua limpia y desinfecte semanalmente. 50 puntos

    - Elimine el estancamiento. 50 puntos.

    - Cancele los huecos no utilizados. 50 puntos



    Tipo de Foco: Plantas ornamentales que acumulan agua

    Método de eliminación:

    - Regar semanalmente con agua clorada con una cucharada sopera por

    cada litro de agua. 50 puntos

    - Retire agua acumulada en las hojas. 50 puntos

    Cambiando puntos

    - Por premios

    En Dengue Torpedo usted juega marcando y eliminando focos, e

    intercambia sus puntos por premios. Los premios disponibles aparecen

    en la sección de Premios de la página principal. Usted también puede

    visualizar los premios disponibles en la página "Gane premios".

    Intercambiar sus puntos por premios es fácil. Usted sólo debe:

    1. Accesar a la página "Gane premios"

    2. Encuentre un cupón de premio que usted quiera intercambiar por sus

    puntos.

    3. Haga clic sobre la imagen o título del cupón. Usted será

    redireccionado a la página del premio.

    4. Lea la descripción del premio y las condiciones para sacarlo.

    5. Haga clic en el botón verde "Usar mis puntos ahora"

    6. Confirmar el uso de los puntos.

    7. Imprimir un cupón de premio. En ese cupón estará su información

    personal, el código del premio, informacion de los patrocinadores y

    datos del retiro.

    8. Ir a un establecimiento autorizado con el cupón impreso y una

    identificación válida con foto (ej. IFE).

    Atención: Usted no puede dar paso atrás una vez que haya utilizado los

    puntos. Una vez apartado, su premio debe ser recogido antes de 7 días

    en el establecimiento del patrocinador siguiendo las instrucciones de

    retiro en su cupón.


    - Por medallas



    Usted gana las medallas automáticamente cuando alcanza la puntuación

    necesaria para cada una. Las medallas aparecen en la página "Mi

    perfil" y no es necesario intercambiar o utilizar los puntos.

    Hay cinco tipos de medallas:

    Enemigo de los mosquitos - 100 puntos

    Exterminador de mosquitos - 450 puntos

    Guerrero DT - 950 puntos

    Guardia de la comunidad - 1350 puntos

    Paladín de la comunidad - 1800 puntos

    - Restituyendo créditos de celular pre-pago

    El valor utilizado para envío de SMS será restituido, o sea, devuleto

    a usted en forma de recarga. Esa recarga entra en firme cuando usted

    acumula la cantidad de textos de Dengue Torpedo requeridos por cada

    operadora, conforme a convenio.


    | Operadora | Máximo acreditado por mês ($) | Quantidad de SMSs de Dengue
    Torpedo requeridos |

    Claro.................. Crédito de $ --...................... 17 SMSs
    DT

    Nextel................ Crédito de $ --....................... 27 SMSs
    DT

    Oi....................... Crédito de $ --..................... 20
    SMSs DT

    Tim........... .........Crédito de $ --...................... 17 SMSs
    DT

    Vivo........... ........Crédito de $ --...................... 20 SMSs
    DT

    Atención:

    - Acuerdese que usted se gana un SMS de Dengue Torpedo por cada foco

    completo enviado por SMS.

    - Cada usuario tendrá derecho a una recarga dos veces por mes.

    - La restitución es realizada automáticamente en forma de recarga de

    crédito para celulares pre-pagados.

    - Las recargas son intransferibles. Es decir, son válidad para los

    números de celulares pre-pagados registrados en Dengue Torpedo.

    - El crédito será otorgado en hasta 7 días (periodo sujeto a

    disponibilidad de sistema) de forma que el usuario tiene que estar

    atento a la cantidad de SMSs de DT que haya hecho.

    - Tipos de premios

    Usted puede usar sus puntos acumulados en Dengue Torpedo para ganar

    premios individuales o comunitarios.

    * Individuales

    Cada premio requiere de una cantidad de puntos. La lista de premios y

    los correspondientes puntos esta en la página "Gane Premios"

    * Comunitarios

    Usted puede usar sus puntos compartiéndolos con sus vecionos y ayudar

    a su comunidad. Consulte la lista completa de premios para las

    comunidades y las reglas específicas en la página "Ganhe Premios".

    * Medallas

    Usted gana las medallas automáticamente. Consulte los detallesen el

    tema "Intercambiando premios" de este manual.

    Mas detalles del sistema de intercambio de puntos pueden ser

    esclarecidos en la sección de preguntas frecuentes.)
    ds.save(:validate => false)


    ds = DocumentationSection.find_by_title("Como participar")
    ds.title_in_es = "¿Cómo participar?"
    ds.content_in_es = %Q(Dengue Torpedo fue lanzado por primera vez en el barrio de Maré, en

    Río. Esta iniciativa será expandida para otros barrios de ciudades. De

    esa forma los moradores de Maré puede participar de esa fase

    pionera.

    Moradores

    ---------

    Cualquier morador de Maré invitado por el equipo de Dengue Torpedo o

    por otro jugador puede participar. Para eso, basta inscribirse en la

    página inicial y comenzar a jugar. En caso de que usted sea

    invitado por otro jugador, hay que completar la información de

    registro en los campos requeridos y mencionar que alguien lo invitó

    a inscribirse a DT.

    Patrocinadores

    --------------

    Cualquier comerciante o prestador de servicios puede participar en

    Dengue Torpedo proporcionando premios individuales o comunitarios.

    Sea comercio o lugar de servicios, tendrá una página propia de

    patrocinador en el sitio de Dengue Torpedo. En esa página apareceran

    los datos del negocio como logo, lugar y teléfono. La página del

    patrocinador tendrá un anuncio de su negocio que verá cualquier

    persona que visite el sitio de Dengue Torpedo. Si su negocio no tiene

    un logo digital, nuestro equipo puede crearlo de acuerdo con sus

    especificaciones. Ese logo digital será suyo, y podrá usarlo para

    cualquier fin que a usted le convenga.

    Verificadores

    -------------

    En Dengue Torpedo algunos participantes tienen un perfil especial

    de verificadores de indentificación y eliminación de focos. En su

    fase actual, el papel del verificador de focos marcados lo fungen

    los agentes comunitarios de la salud (ACS) y los agentes de

    vigilancia sanitaria (AVS).

    Los verificadores también pueden ser convocados para mediar

    conflictos, auxiliar con informaciónes técnicas y promover oficinas

    de vigilancia epidemiológica para Dengue.



    Sepa más sobre esas actividades de los verificadores accesando "Mi
    comunidad")
    ds.save(:validate => false)

    ds = DocumentationSection.find_by_title("Minha comunidade")
    ds.title_in_es = "Mi comunidad"
    ds.content_in_es = %Q(La página "Mi comunidad" es donde usted encontrará las casas

    participantes y otros asuntos de su comunidad (noticias, y otras

    actividades).)
    ds.save(:validate => false)




  end

  #----------------------------------------------------------------------------

end
