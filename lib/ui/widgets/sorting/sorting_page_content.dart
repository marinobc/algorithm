import 'package:flutter/material.dart';

/// Video recomendado dentro de una página explicativa de ordenamiento.
class SortingVideo {
  final String title;
  final String description;
  final String url;
  final String label;

  const SortingVideo({
    required this.title,
    required this.description,
    required this.url,
    required this.label,
  });
}

/// Una fila de la traza de ejemplo (estado del arreglo tras cada paso).
class SortingTraceRow {
  final String label;
  final String state;
  final String note;

  const SortingTraceRow(this.label, this.state, this.note);
}

/// Contenido textual completo de la página de un algoritmo de ordenamiento.
///
/// Vive separado de la UI para poder editar los textos y los enlaces de video
/// sin tocar widgets.
class SortingPageContent {
  final String badge;
  final IconData badgeIcon;
  final IconData heroIcon;
  final String intro;

  final String conceptEyebrow;
  final String conceptTitle;
  final String conceptBody;
  final String conceptExtra;

  final String how;
  final String howExtra;

  final String analogyTitle;
  final String analogyBody;

  /// (título, descripción corta, detalle ampliado)
  final List<(String, String, String)> steps;

  final String example;
  final List<SortingTraceRow> trace;

  final String complexity;
  final String complexityDetails;
  final String complexityExtra;

  /// (etiqueta, valor)
  final List<(String, String)> metrics;

  final List<String> pros;
  final List<String> cons;

  final String whenTitle;
  final String whenBody;

  final String cta;

  final List<SortingVideo> videos;

  const SortingPageContent({
    required this.badge,
    required this.badgeIcon,
    required this.heroIcon,
    required this.intro,
    required this.conceptEyebrow,
    required this.conceptTitle,
    required this.conceptBody,
    required this.conceptExtra,
    required this.how,
    required this.howExtra,
    required this.analogyTitle,
    required this.analogyBody,
    required this.steps,
    required this.example,
    required this.trace,
    required this.complexity,
    required this.complexityDetails,
    required this.complexityExtra,
    required this.metrics,
    required this.pros,
    required this.cons,
    required this.whenTitle,
    required this.whenBody,
    required this.cta,
    required this.videos,
  });

  static SortingPageContent forId(String id) => switch (id) {
    'selection' => _selection,
    'insertion' => _insertion,
    'shell' => _shell,
    _ => _merge,
  };

  // ---------------------------------------------------------------------------
  // SELECTION SORT
  // ---------------------------------------------------------------------------
  static const _selection = SortingPageContent(
    badge: 'Ordenamiento por selección',
    badgeIcon: Icons.sort_rounded,
    heroIcon: Icons.sort_rounded,
    intro:
        'Encuentra el menor elemento del tramo pendiente y colócalo en su posición definitiva.',
    conceptEyebrow: 'LA IDEA EN UNA FRASE',
    conceptTitle: '¿Por qué se llama "selección"?',
    conceptBody:
        'Porque en cada pasada el algoritmo selecciona al mejor candidato: el menor valor que todavía no está ordenado. Una vez elegido, no vuelve a moverlo nunca más; ya está en su lugar definitivo.',
    conceptExtra:
        'Es uno de los primeros algoritmos que se estudian porque se puede explicar sin trucos: buscar el mínimo y ponerlo al principio, una y otra vez, hasta que no quede nada por ordenar.',
    how:
        'Selection Sort divide el arreglo en una parte ordenada y otra pendiente. En cada recorrido busca el valor mínimo de la parte pendiente y lo intercambia con el primer elemento de esa parte.',
    howExtra:
        'Al principio la parte ordenada está vacía y la pendiente es todo el arreglo. Después de cada pasada la frontera avanza una posición hacia la derecha, de modo que la parte ordenada crece de a un elemento y la pendiente se reduce. Cuando solo queda un elemento pendiente, el arreglo completo está ordenado.',
    analogyTitle: 'Ejemplo cotidiano: ordenar cartas en la mano',
    analogyBody:
        'Imagina que tienes cartas numeradas boca arriba sobre la mesa. Buscas la más pequeña, la pones en la primera posición de tu mano; luego buscas la más pequeña de las que quedan y la pones en la segunda posición, y así hasta terminar. Eso es exactamente lo que hace Selection Sort.',
    steps: [
      (
        '1. Elige una posición',
        'Comienza por el primer lugar que todavía no está ordenado.',
        'Llamemos i a esa posición. Todo lo que está a la izquierda de i ya es definitivo; todo lo que está desde i hacia la derecha sigue pendiente.',
      ),
      (
        '2. Busca el mínimo',
        'Compara todos los elementos restantes y conserva el menor encontrado.',
        'Recorre desde i hasta el final recordando la posición del valor más pequeño visto hasta ahora. Cada vez que aparece uno menor, ese pasa a ser el nuevo mínimo.',
      ),
      (
        '3. Intercambia',
        'Mueve el mínimo a la posición elegida. Repite con la siguiente posición.',
        'Se intercambia el mínimo con el elemento que estaba en i. Si el mínimo ya estaba en i, no hay nada que mover. Luego i avanza una posición y se repite hasta llegar al penúltimo elemento.',
      ),
    ],
    example:
        'Ejemplo: [8, 3, 6, 2] → el mínimo es 2 → se intercambia con 8 → [2, 3, 6, 8].',
    trace: [
      SortingTraceRow('Inicio', '[8, 3, 6, 2]', 'Todo el arreglo está pendiente.'),
      SortingTraceRow(
        'Pasada 1',
        '[2, 3, 6, 8]',
        'El mínimo es 2 (posición 3): se intercambia con el 8 de la posición 0.',
      ),
      SortingTraceRow(
        'Pasada 2',
        '[2, 3, 6, 8]',
        'El mínimo de [3, 6, 8] es 3 y ya está en su lugar.',
      ),
      SortingTraceRow(
        'Pasada 3',
        '[2, 3, 6, 8]',
        'El mínimo de [6, 8] es 6 y ya está en su lugar. Fin.',
      ),
    ],
    complexity: 'n(n - 1) / 2 ≈ n² / 2',
    complexityDetails:
        'Realiza n(n - 1) / 2 comparaciones, incluso si los datos ya estaban ordenados. Complejidad temporal: O(n²).',
    complexityExtra:
        'Su comportamiento es muy predecible: siempre hace la misma cantidad de comparaciones sin importar el orden inicial. En cambio, el número de intercambios es pequeño (como máximo n - 1), lo que lo vuelve útil cuando mover datos es costoso.',
    metrics: [
      ('Mejor caso', 'O(n²)'),
      ('Caso promedio', 'O(n²)'),
      ('Peor caso', 'O(n²)'),
      ('Espacio extra', 'O(1)'),
      ('Intercambios', 'máx. n - 1'),
      ('Estable', 'No'),
    ],
    pros: [
      'Muy fácil de entender e implementar.',
      'Hace pocos intercambios: como máximo n - 1.',
      'Ordena in situ, sin memoria adicional.',
      'Su tiempo es predecible, no depende del orden inicial.',
    ],
    cons: [
      'Siempre cuesta O(n²), aunque los datos ya estén ordenados.',
      'No aprovecha el orden parcial que ya exista.',
      'No es estable: puede alterar el orden de elementos iguales.',
      'Poco práctico para conjuntos de datos grandes.',
    ],
    whenTitle: '¿Cuándo conviene usarlo?',
    whenBody:
        'Es una buena opción para listas pequeñas, para enseñar cómo funciona un ordenamiento y cuando escribir en memoria es mucho más caro que leer (por ejemplo, memorias flash). Para grandes volúmenes de datos es preferible un algoritmo de tipo n log n.',
    cta:
        'Observa cómo el mínimo viaja a su posición definitiva y cuenta las comparaciones en tiempo real.',
    videos: [
      SortingVideo(
        title: 'Video 1: Selection Sort paso a paso',
        description:
            'Explicación en español con prueba de escritorio: sigue cómo cambian las posiciones en cada pasada.',
        url: 'https://www.youtube.com/watch?v=wJzJIX0CYI0',
        label: 'Prueba de escritorio',
      ),
      SortingVideo(
        title: 'Video 2: la idea del ordenamiento por selección',
        description:
            'Una introducción clara al concepto, ideal para repasar antes de probar el laboratorio.',
        url: 'https://www.youtube.com/watch?v=Myy-eU-SWbE',
        label: 'Introducción',
      ),
      SortingVideo(
        title: 'Video 3: Selection Sort bailado',
        description:
            'Una forma distinta y memorable de ver cómo se elige el mínimo y se intercambia.',
        url: 'https://www.youtube.com/watch?v=Ns4TPTC8whw',
        label: 'Visualización con baile',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // INSERTION SORT
  // ---------------------------------------------------------------------------
  static const _insertion = SortingPageContent(
    badge: 'Ordenamiento por inserción',
    badgeIcon: Icons.low_priority_rounded,
    heroIcon: Icons.low_priority_rounded,
    intro:
        'Toma cada elemento y ubícalo en el lugar correcto dentro de la parte ya ordenada.',
    conceptEyebrow: 'LA IDEA EN UNA FRASE',
    conceptTitle: '¿Por qué se llama "inserción"?',
    conceptBody:
        'Porque en cada paso toma un elemento nuevo y lo inserta en el lugar que le corresponde dentro de la parte que ya está ordenada, desplazando a los mayores un espacio hacia la derecha.',
    conceptExtra:
        'Es el método que usamos de forma natural al ordenar a mano. Su gran ventaja es que se adapta a los datos: si el arreglo ya viene casi ordenado, casi no tiene trabajo que hacer.',
    how:
        'Insertion Sort construye una región ordenada de izquierda a derecha. Extrae el elemento actual, desplaza a la derecha los valores mayores y lo inserta en el espacio que queda.',
    howExtra:
        'El primer elemento se considera ordenado por sí solo. Luego se toma el segundo, el tercero, y así sucesivamente: cada uno (la "clave") se compara hacia la izquierda con los elementos ya ordenados. Los que son mayores se corren un lugar a la derecha para abrir un hueco, y la clave cae en ese hueco.',
    analogyTitle: 'Ejemplo cotidiano: ordenar cartas de una baraja',
    analogyBody:
        'Cuando repartes cartas y las vas tomando una por una, cada carta nueva la colocas en su sitio entre las que ya tienes ordenadas en la mano: la comparas con las anteriores, corres las mayores y la insertas. Eso es Insertion Sort.',
    steps: [
      (
        '1. Extrae la clave',
        'Toma el siguiente elemento a la derecha de la región ordenada.',
        'La clave se "levanta" temporalmente del arreglo. Todo lo que está a su izquierda ya está ordenado entre sí, aunque todavía no sea la posición definitiva de cada valor.',
      ),
      (
        '2. Desplaza',
        'Compara hacia la izquierda y mueve una posición a la derecha cada valor mayor.',
        'Se avanza hacia la izquierda comparando la clave con cada elemento ordenado. Mientras el elemento comparado sea mayor que la clave, se corre una posición a la derecha. Se detiene al encontrar uno menor o igual, o al llegar al inicio.',
      ),
      (
        '3. Inserta',
        'Coloca la clave en el espacio libre y amplía la región ordenada.',
        'El hueco que quedó libre es justo el lugar que le corresponde a la clave. Al colocarla ahí, la región ordenada crece en un elemento y se pasa a la siguiente clave.',
      ),
    ],
    example:
        'Ejemplo: [3, 7, 4, 9] → la clave es 4 → 7 se desplaza → [3, 4, 7, 9].',
    trace: [
      SortingTraceRow('Inicio', '[3, 7, 4, 9]', 'La región ordenada es solo [3].'),
      SortingTraceRow(
        'Clave 7',
        '[3, 7, 4, 9]',
        '3 es menor que 7, así que 7 se queda donde está.',
      ),
      SortingTraceRow(
        'Clave 4',
        '[3, 4, 7, 9]',
        '7 es mayor que 4 y se desplaza a la derecha; 3 es menor, así que 4 se inserta ahí.',
      ),
      SortingTraceRow(
        'Clave 9',
        '[3, 4, 7, 9]',
        '7 es menor que 9: no hay desplazamientos. Fin.',
      ),
    ],
    complexity: 'n² / 4',
    complexityDetails:
        'La aproximación utilizada en la materia es n² / 4. El trabajo depende del orden inicial de los datos; su complejidad temporal es O(n²).',
    complexityExtra:
        'Si el arreglo ya está ordenado, cada clave se compara una sola vez y el costo baja a O(n). Si está en orden inverso, cada clave debe recorrer toda la región ordenada y el costo se acerca al máximo. Por eso se dice que es un algoritmo adaptativo.',
    metrics: [
      ('Mejor caso', 'O(n)'),
      ('Caso promedio', 'O(n²)'),
      ('Peor caso', 'O(n²)'),
      ('Espacio extra', 'O(1)'),
      ('Adaptativo', 'Sí'),
      ('Estable', 'Sí'),
    ],
    pros: [
      'Muy rápido en datos casi ordenados (mejor caso O(n)).',
      'Es estable: respeta el orden de elementos iguales.',
      'Ordena in situ, sin memoria adicional.',
      'Puede ordenar a medida que llegan los datos.',
    ],
    cons: [
      'Cuesta O(n²) en promedio y en el peor caso.',
      'Mueve muchos elementos de a una posición a la vez.',
      'Es lento con arreglos grandes y desordenados.',
    ],
    whenTitle: '¿Cuándo conviene usarlo?',
    whenBody:
        'Funciona muy bien con listas pequeñas y con datos que ya vienen casi ordenados. Por eso muchas implementaciones profesionales lo usan como paso final o para tramos cortos dentro de algoritmos más rápidos.',
    cta:
        'Mira cómo la clave se eleva, los mayores se desplazan y el hueco se llena con el valor correcto.',
    videos: [
      SortingVideo(
        title: 'Video 1: Insertion Sort paso a paso',
        description:
            'Explicación en español con prueba de escritorio del ordenamiento por inserción.',
        url: 'https://www.youtube.com/watch?v=8rhtmJ7nurM',
        label: 'Prueba de escritorio',
      ),
      SortingVideo(
        title: 'Video 2: explicación, pseudocódigo y complejidad',
        description:
            'Cubre la idea general, el pseudocódigo y el análisis de complejidad con un visualizador.',
        url: 'https://www.youtube.com/watch?v=6GU6AGEWYJY',
        label: 'Teoría y código',
      ),
      SortingVideo(
        title: 'Video 3: Insertion Sort bailado',
        description:
            'Observa cómo cada elemento se inserta en la fila ordenada mediante una coreografía.',
        url: 'https://www.youtube.com/watch?v=ROalU379l3U',
        label: 'Visualización con baile',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // SHELL SORT
  // ---------------------------------------------------------------------------
  static const _shell = SortingPageContent(
    badge: 'Inserción con saltos',
    badgeIcon: Icons.space_bar_rounded,
    heroIcon: Icons.space_bar_rounded,
    intro:
        'Ordena elementos distantes entre sí; reduce el gap hasta llegar a una inserción final con gap 1.',
    conceptEyebrow: 'LA IDEA EN UNA FRASE',
    conceptTitle: '¿Qué es el "gap"?',
    conceptBody:
        'El gap es la distancia entre los elementos que se comparan en cada pasada. Con un gap grande, los valores mueven grandes distancias de un solo salto; con gap 1 el algoritmo se comporta como una inserción normal.',
    conceptExtra:
        'Shell Sort fue propuesto por Donald Shell en 1959. Su truco es que Insertion Sort es muy rápido con datos casi ordenados, así que primero "casi ordena" el arreglo con saltos grandes y deja la inserción fina para el final.',
    how:
        'Shell Sort aplica inserción a subsecuencias separadas por incrementos de Knuth (1, 4, 13, …). Cada pasada reduce el gap; la última, con gap 1, termina de ordenar.',
    howExtra:
        'La secuencia de Knuth sigue la regla h = 3h + 1 (1, 4, 13, 40, …). Se elige el mayor gap que sea razonable para el tamaño del arreglo y se va reduciendo. Cada pasada deja al arreglo "h-ordenado": los elementos separados por h posiciones ya quedan en orden relativo, lo que prepara el terreno para la pasada siguiente.',
    analogyTitle: 'Ejemplo cotidiano: ordenar una fila de personas por estatura',
    analogyBody:
        'En vez de pedir que vecinos contiguos se intercambien, primero haces que personas muy separadas en la fila se comparen y se cambien de lugar. Así los más altos viajan rápido hacia el final y los más bajos al inicio. Luego acortas la distancia hasta que solo corriges ajustes pequeños entre vecinos.',
    steps: [
      (
        '1. Calcula el gap',
        'Usa el mayor incremento de Knuth apropiado para el tamaño.',
        'Se parte de gap = 1 y se multiplica por 3 sumando 1 mientras el gap siga siendo pequeño respecto al tamaño del arreglo. Para pocos elementos el gap inicial puede ser 1 o muy cercano.',
      ),
      (
        '2. Ordena subsecuencias',
        'Compara elementos separados por el gap y desplaza los mayores.',
        'Los elementos que están a gap posiciones entre sí forman subsecuencias independientes. Cada una se ordena con inserción: se toma una clave, se compara con el elemento que está gap lugares atrás y se desplaza si es mayor.',
      ),
      (
        '3. Reduce el gap',
        'Repite hasta completar una pasada con gap 1.',
        'Tras cada pasada se pasa al siguiente gap menor de la secuencia (por ejemplo 13 → 4 → 1). La pasada final con gap 1 es una inserción clásica, pero sobre un arreglo que ya está casi ordenado, así que termina muy rápido.',
      ),
    ],
    example:
        'Ejemplo: [8, 3, 6, 2] → gap 1 → inserción con desplazamientos → [2, 3, 6, 8].',
    trace: [
      SortingTraceRow(
        'Arreglo',
        '[8, 3, 6, 2, 7, 1, 5, 4]',
        'Ejemplo más grande para ver el efecto de un gap mayor que 1.',
      ),
      SortingTraceRow(
        'Gap 4',
        '[7, 1, 5, 2, 8, 3, 6, 4]',
        'Se comparan las parejas (8,7), (3,1), (6,5) y (2,4): las tres primeras se intercambian.',
      ),
      SortingTraceRow(
        'Gap 1',
        '[1, 2, 3, 4, 5, 6, 7, 8]',
        'Inserción final sobre un arreglo casi ordenado: pocos desplazamientos. Fin.',
      ),
    ],
    complexity: 'Θ(n³ᐟ²) peor caso',
    complexityDetails:
        'Con incrementos de Knuth, el peor caso es Θ(n³ᐟ²). Se ordena in situ; las comparaciones y desplazamientos reales se muestran en el laboratorio.',
    complexityExtra:
        'La complejidad exacta de Shell Sort depende de la secuencia de gaps elegida: con la secuencia original de Shell (n/2, n/4, …) el peor caso es O(n²), mientras que con la de Knuth baja a Θ(n³ᐟ²). En la práctica suele ser mucho más rápido que Insertion Sort sin necesitar memoria adicional.',
    metrics: [
      ('Mejor caso', 'O(n log n)'),
      ('Caso promedio', 'según el gap'),
      ('Peor caso (Knuth)', 'Θ(n³ᐟ²)'),
      ('Espacio extra', 'O(1)'),
      ('Adaptativo', 'Sí'),
      ('Estable', 'No'),
    ],
    pros: [
      'Mucho más rápido que la inserción simple en arreglos medianos.',
      'Ordena in situ, sin memoria adicional.',
      'Es fácil de implementar a partir de la inserción.',
      'Aprovecha el orden parcial gracias a las pasadas con gap.',
    ],
    cons: [
      'Su rendimiento depende de la secuencia de gaps elegida.',
      'No es estable: los saltos pueden alterar elementos iguales.',
      'Su análisis teórico es más difícil que el de otros métodos.',
      'Para datos muy grandes hay algoritmos n log n garantizados.',
    ],
    whenTitle: '¿Cuándo conviene usarlo?',
    whenBody:
        'Es una mejora sencilla cuando se quiere algo más rápido que la inserción sin recurrir a recursión ni a memoria extra. Se usa en sistemas embebidos y en situaciones donde importa un código pequeño y un uso mínimo de memoria.',
    cta:
        'Observa cómo cambia el gap en cada pasada y cómo los elementos lejanos se acercan a su lugar.',
    videos: [
      SortingVideo(
        title: 'Video 1: Shell Sort paso a paso',
        description:
            'Explicación en español con prueba de escritorio, útil para seguir cada gap.',
        url: 'https://www.youtube.com/watch?v=vwn514rBtNc',
        label: 'Prueba de escritorio',
      ),
      SortingVideo(
        title: 'Video 2: funcionamiento gráfico del método Shell',
        description:
            'Describe gráficamente cómo se agrupan y ordenan los elementos según el incremento.',
        url: 'https://www.youtube.com/watch?v=9GAtGHVRYh0',
        label: 'Explicación gráfica',
      ),
      SortingVideo(
        title: 'Video 3: Shell Sort bailado',
        description:
            'Una coreografía que muestra cómo los saltos grandes se reducen hasta llegar a gap 1.',
        url: 'https://www.youtube.com/watch?v=CmPA7zE8mx0',
        label: 'Visualización con baile',
      ),
    ],
  );

  // ---------------------------------------------------------------------------
  // MERGE SORT
  // ---------------------------------------------------------------------------
  static const _merge = SortingPageContent(
    badge: 'Divide y vencerás',
    badgeIcon: Icons.call_merge_rounded,
    heroIcon: Icons.call_merge_rounded,
    intro:
        'Divide el conjunto en dos mitades, ordena cada mitad y fusiónalas comparando sus elementos.',
    conceptEyebrow: 'LA IDEA EN UNA FRASE',
    conceptTitle: '¿Qué significa "divide y vencerás"?',
    conceptBody:
        'Es una estrategia que parte un problema grande en problemas más pequeños de la misma forma, los resuelve por separado y combina las respuestas. Ordenar una lista de un solo elemento es trivial: ya está ordenada.',
    conceptExtra:
        'Merge Sort fue propuesto por John von Neumann en 1945. Su secreto es que fusionar dos listas que ya están ordenadas es muy barato: basta con mirar el primer elemento pendiente de cada una y quedarse con el menor.',
    how:
        'Merge Sort divide recursivamente en dos mitades hasta obtener tramos de un elemento. Después fusiona cada par de mitades ya ordenadas, eligiendo el menor elemento disponible.',
    howExtra:
        'El algoritmo tiene dos fases. En la de división se parte el arreglo por la mitad una y otra vez hasta llegar a tramos de tamaño 1. En la de fusión se recorre el camino de vuelta: cada par de tramos ordenados se combina en uno más grande y ordenado, hasta reconstruir el arreglo completo.',
    analogyTitle: 'Ejemplo cotidiano: unir dos montones de exámenes',
    analogyBody:
        'Dos profesores corrigen cada uno la mitad de los exámenes y los dejan ordenados por nota. Para juntarlos en un solo montón ordenado, basta con mirar el examen de arriba de cada pila y pasar siempre el de menor nota. Merge Sort aplica esa misma idea una y otra vez.',
    steps: [
      (
        '1. Divide',
        'Separa el tramo en mitades hasta llegar a elementos individuales.',
        'Se calcula el punto medio y se parte el tramo en una mitad izquierda y otra derecha. El proceso se repite sobre cada mitad hasta que cada tramo tenga un solo elemento, que por definición ya está ordenado.',
      ),
      (
        '2. Ordena ambas mitades',
        'Resuelve primero la mitad izquierda y después la derecha.',
        'La recursión se encarga: se llama al mismo algoritmo sobre la mitad izquierda y luego sobre la derecha. Cuando ambas terminan, se tienen dos tramos ordenados listos para unirse.',
      ),
      (
        '3. Fusiona',
        'Compara sus primeros elementos pendientes y escribe el menor en la salida.',
        'Se usan dos punteros, uno por tramo. Se compara el elemento apuntado en cada uno, se copia el menor al resultado y se avanza ese puntero. Cuando un tramo se agota, se copia lo que queda del otro.',
      ),
    ],
    example:
        'Ejemplo: [8, 3, 6, 2] → [3, 8] y [2, 6] → fusión → [2, 3, 6, 8].',
    trace: [
      SortingTraceRow('Inicio', '[8, 3, 6, 2]', 'Un solo tramo de 4 elementos.'),
      SortingTraceRow(
        'División',
        '[8, 3]  |  [6, 2]',
        'Se parte en dos mitades y cada una se vuelve a dividir hasta quedar en elementos sueltos.',
      ),
      SortingTraceRow(
        'Fusión pequeña',
        '[3, 8]  |  [2, 6]',
        'Cada pareja se fusiona ordenada: 3 antes que 8, y 2 antes que 6.',
      ),
      SortingTraceRow(
        'Fusión final',
        '[2, 3, 6, 8]',
        'Se compara 3 con 2 (sale 2), 3 con 6 (sale 3), 8 con 6 (sale 6) y finalmente sale 8.',
      ),
    ],
    complexity: 'Θ(n log n)',
    complexityDetails:
        'Divide y fusiona en Θ(n log n) tiempo incluso en el peor caso. La fusión requiere Θ(n) espacio auxiliar.',
    complexityExtra:
        'El arreglo se divide en log n niveles y en cada nivel se recorren los n elementos para fusionar, de ahí n log n. Es una de las pocas opciones con tiempo garantizado en todos los casos, a cambio de usar memoria adicional proporcional al tamaño de los datos.',
    metrics: [
      ('Mejor caso', 'Θ(n log n)'),
      ('Caso promedio', 'Θ(n log n)'),
      ('Peor caso', 'Θ(n log n)'),
      ('Espacio extra', 'Θ(n)'),
      ('Recursivo', 'Sí'),
      ('Estable', 'Sí'),
    ],
    pros: [
      'Tiempo garantizado Θ(n log n) en todos los casos.',
      'Es estable: respeta el orden de elementos iguales.',
      'Escala muy bien a conjuntos de datos grandes.',
      'Ideal para listas enlazadas y datos externos.',
    ],
    cons: [
      'Necesita Θ(n) de memoria auxiliar para fusionar.',
      'Es más complejo de implementar que los métodos cuadráticos.',
      'Para arreglos muy pequeños suele ser más lento que la inserción.',
    ],
    whenTitle: '¿Cuándo conviene usarlo?',
    whenBody:
        'Es la elección habitual cuando se necesita un tiempo predecible con muchos datos o cuando la estabilidad importa. Se usa, por ejemplo, para ordenar archivos que no caben en memoria y como base de los ordenamientos estándar de varios lenguajes.',
    cta:
        'Sigue cómo se dividen los tramos y cómo la fusión elige siempre el menor elemento disponible.',
    videos: [
      SortingVideo(
        title: 'Video 1: Merge Sort explicado',
        description:
            'Introducción al ordenamiento por mezcla como ejemplo clásico del patrón divide y vencerás.',
        url: 'https://www.youtube.com/watch?v=ACFZn_xQcz8',
        label: 'Explicación principal',
      ),
      SortingVideo(
        title: 'Video 2: Merge Sort bailado',
        description:
            'Una coreografía que muestra cómo se dividen los grupos y cómo se fusionan de forma ordenada.',
        url: 'https://youtu.be/XaqR3G_NVoo',
        label: 'Visualización con baile',
      ),
    ],
  );
}
