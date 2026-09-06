abstract final class DialogText {
  static const deleteNodeTitle = 'Eliminar Nodo';
  static const confirmDeleteNode =
      '¿Está seguro de que desea eliminar este nodo?';

  static String confirmDeleteNamedNode(String name) =>
      '¿Está seguro de que desea eliminar el nodo $name?';

  static String confirmDeleteNodeConnections(int count) =>
      'También se eliminarán $count conexiones:';

  static const deleteConnectionTitle = 'Eliminar Conexión';
  static const confirmDeleteConnection =
      '¿Está seguro de que desea eliminar esta conexión?';

  static const unsavedChangesTitle = 'Cambios no guardados';
  static const confirmExitUnsavedChanges =
      '¿Desea salir sin guardar los cambios?';

  static const nodeProperties = 'Propiedades del Nodo';
  static const nodeName = 'Nombre del nodo';
  static const nodeColor = 'Color del nodo';
}
