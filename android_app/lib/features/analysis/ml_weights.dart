class MlWeights {
  static const List<String> classes = ['danger', 'safe', 'suspicious'];

  static const List<List<double>> coef = [
      [-1.26296704, -0.45762695, 0.57548819, 0.83463601, 0.40598164, 1.32110072],
      [0.66921155, 2.91807397, -0.39121324, -0.54558184, 0.02034028, -5.25418069],
      [0.59375549, -2.46044703, -0.18427495, -0.28905416, -0.42632192, 3.93307997],
  ];

  static const List<double> intercept = [1.58511139, -1.48884358, -0.09626780];

  static const List<double> scalerMean = [0.19668522, 1.28351178, 1.19486081, 0.04668094, 2.19862193, 4.70835118];
  static const List<double> scalerScale = [0.11966431, 0.73350971, 2.53052781, 0.21095457, 0.99813413, 5.54160388];
}
