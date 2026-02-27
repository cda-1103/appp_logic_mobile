import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/game_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gameVM = Provider.of<GameViewModel>(context);
    final challenge = gameVM.currentChallenge;

    final neonGreen = const Color(0xFF00FF00);
    final neonRed = const Color(0xFFFF3131);
    final darkBg = const Color(0xFF0D1117);
    final aiColor = const Color(0xFF9C27B0); // Morado neón para la IA

    // 1. LOADING STATE
    if (challenge == null) {
      return Scaffold(
        backgroundColor: darkBg,
        body: Center(child: CircularProgressIndicator(color: neonGreen)),
      );
    }

    final options = gameVM.currentShuffledOptions;

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Column(
          children: [
            Text(
              "LEVEL PROGRESS",
              style: TextStyle(
                color: neonGreen,
                fontSize: 10,
                fontFamily: 'Courier',
                letterSpacing: 2,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(gameVM.currentLives, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    index < gameVM.currentLives
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: neonRed,
                    size: 20,
                  ),
                );
              }),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: LinearProgressIndicator(
            value: (gameVM.currentQuestionIndex + 1) / gameVM.totalQuestions,
            backgroundColor: Colors.white10,
            valueColor: AlwaysStoppedAnimation<Color>(neonGreen),
          ),
        ),
      ),
      body: Column(
        children: [
          // --- CONTENIDO SCROLLABLE ---
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    challenge.question,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (challenge.codeSnippet != null &&
                      challenge.codeSnippet!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF161B22),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        challenge.codeSnippet!,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  if (challenge.isFillInTheBlank)
                    _buildTextFieldInput(context, gameVM, neonGreen, neonRed)
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: options.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        return _buildOptionCard(
                          index,
                          gameVM,
                          options[index],
                          neonGreen,
                          neonRed,
                        );
                      },
                    ),
                ],
              ),
            ),
          ),

          // --- ÁREA DE ACCIÓN ---
          if (!gameVM.isChecked)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (challenge.isFillInTheBlank && gameVM.userInputText.trim().isEmpty) || 
                             (!challenge.isFillInTheBlank && gameVM.selectedOptionIndex == null)
                      ? null
                      : () {
                          FocusScope.of(context).unfocus(); 
                          gameVM.checkAnswer();
                          if (gameVM.currentLives <= 0) {
                            _showGameOverDialog(context);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: Colors.grey[800],
                  ),
                  child: const Text(
                    "RESPONDER",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),

          if (gameVM.isChecked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: gameVM.isCorrect
                    ? const Color(0xFF052e16)
                    : const Color(0xFF2D1B1B),
                border: Border(
                  top: BorderSide(
                    color: gameVM.isCorrect ? neonGreen : neonRed,
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        gameVM.isCorrect ? Icons.check_circle : Icons.cancel,
                        color: gameVM.isCorrect ? neonGreen : neonRed,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        gameVM.isCorrect ? "CORRECTO!" : "INCORRECTO!",
                        style: TextStyle(
                          color: gameVM.isCorrect ? neonGreen : neonRed,
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Explicación estática del JSON
                  if (challenge.explanation.isNotEmpty)
                    Text(
                      challenge.explanation,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    
                  if (!gameVM.isCorrect && challenge.isFillInTheBlank && challenge.expectedTextAnswer != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      "Respuesta esperada: ${challenge.expectedTextAnswer}",
                      style: TextStyle(
                        color: neonGreen,
                        fontFamily: 'Courier',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  // ------------------------------------------------------------------
                  // ---> SECCIÓN DE INTELIGENCIA ARTIFICIAL (MENTOR BOT) <---
                  // ------------------------------------------------------------------
                  if (!gameVM.isCorrect) ...[
                    const SizedBox(height: 20),
                    // Si ya hay una pista cargada, la mostramos
                    if (gameVM.currentHint != null)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: aiColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: aiColor.withOpacity(0.5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.psychology, color: aiColor, size: 28),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                gameVM.currentHint!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    // Si no hay pista y no está cargando, mostramos el botón para pedirla
                    else if (!gameVM.isLoadingHint)
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => gameVM.askForHint(),
                          icon: Icon(Icons.auto_awesome, color: aiColor),
                          label: Text(
                            "PEDIR PISTA AL MENTOR IA",
                            style: TextStyle(color: aiColor, fontWeight: FontWeight.bold),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: aiColor),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      )
                    // Si está cargando, mostramos el indicador
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: aiColor),
                        ),
                      ),
                  ],
                  // ------------------------------------------------------------------

                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gameVM.isCorrect ? neonGreen : neonRed,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      onPressed: () {
                        bool isLastQuestion =
                            gameVM.currentQuestionIndex >=
                            gameVM.totalQuestions - 1;

                        if (!isLastQuestion) {
                          gameVM.nextQuestion();
                        } else {
                          _handleLevelFinish(context, gameVM);
                        }
                      },
                      child: Text(
                        (gameVM.currentQuestionIndex >=
                                gameVM.totalQuestions - 1)
                            ? "TERMINAR NIVEL >"
                            : "CONTINUAR >",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextFieldInput(BuildContext context, GameViewModel gameVM, Color green, Color red) {
    Color borderColor = Colors.blueAccent;
    if (gameVM.isChecked) {
      borderColor = gameVM.isCorrect ? green : red;
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B22),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: gameVM.isChecked ? 2 : 1),
      ),
      child: TextField(
        controller: gameVM.textController,
        enabled: !gameVM.isChecked, 
        autofocus: true, 
        style: const TextStyle(color: Colors.white, fontFamily: 'Courier', fontSize: 16),
        cursorColor: green,
        onChanged: (text) => gameVM.updateUserInput(text),
        decoration: InputDecoration(
          hintText: "Escribe tu código aquí...",
          hintStyle: TextStyle(color: Colors.white38, fontFamily: 'Courier'),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          suffixIcon: gameVM.isChecked
              ? Icon(
                  gameVM.isCorrect ? Icons.check : Icons.close,
                  color: borderColor,
                )
              : const Icon(Icons.keyboard, color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    int index,
    GameViewModel gameVM,
    String text,
    Color green,
    Color red,
  ) {
    final isSelected = gameVM.selectedOptionIndex == index;
    Color borderColor = Colors.white10;
    Color bgColor = const Color(0xFF161B22);

    if (gameVM.isChecked) {
      final challenge = gameVM.currentChallenge!;
      final correctText = challenge.options[challenge.correctOptionIndex];
      
      bool isThisCardTheCorrectOne = (text == correctText);

      if (isThisCardTheCorrectOne) {
        borderColor = green;
        bgColor = green.withOpacity(0.1);
      } else if (isSelected && !gameVM.isCorrect) {
        borderColor = red;
        bgColor = red.withOpacity(0.1);
      }
    } else {
      if (isSelected) {
        borderColor = Colors.blueAccent;
        bgColor = Colors.blueAccent.withOpacity(0.1);
      }
    }

    return GestureDetector(
      onTap: gameVM.isChecked ? null : () => gameVM.selectOption(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width:
                isSelected ||
                    (gameVM.isChecked && borderColor != Colors.white10)
                ? 2
                : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(10),
                color: isSelected ? borderColor : null,
              ),
              child: isSelected && gameVM.isChecked
                  ? Icon(
                      gameVM.isCorrect ? Icons.check : Icons.close,
                      size: 14,
                      color: Colors.black,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLevelFinish(BuildContext context, GameViewModel gameVM) async {
    final authVM = Provider.of<AuthViewModel>(context, listen: false);

    bool passed = await gameVM.finishLevel();
    await authVM.reloadUser();

    if (!context.mounted) return;

    if (passed) {
      _showVictoryDialog(context, gameVM);
    } else {
      _showDefeatDialog(context);
    }
  }

  void _showVictoryDialog(BuildContext context, GameViewModel gameVM) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00FF00)),
        ),
        title: const Icon(Icons.emoji_events, color: Colors.yellow, size: 50),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "NIVEL COMPLETADO!",
              style: TextStyle(
                color: Color(0xFF00FF00),
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Score: ${gameVM.score} XP",
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: const Text(
              "REGRESA AL MENÚ >",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDefeatDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.orange),
        ),
        title: const Icon(Icons.warning, color: Colors.orange, size: 50),
        content: const Text(
          "Accuracy too low.\nRetry mission.",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text(
              "RETRY >",
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161B22),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: Colors.red),
        ),
        title: const Icon(Icons.dangerous, color: Colors.red, size: 50),
        content: const Text(
          "SYSTEM FAILURE\nLives depleted.",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("EXIT >", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}