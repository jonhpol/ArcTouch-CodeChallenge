//
//  QuizViewController.swift
//  WordQuiz
//
//  Created by João Paulo de Oliveira Sabino on 13/12/19.
//  Copyright © 2019 João Paulo de Oliveira Sabino. All rights reserved.
//

import UIKit

class QuizViewController: UIViewController {
    let quizView = QuizView()
    var quizViewModel = QuizViewModel()
    
    var dataSource: QuizTableDataSource {
        return quizViewModel.dataSource
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupDataSource()
        quizViewModel.getQuiz(id: 1)
        quizViewModel.quizStatusDelegate = self
        quizView.textFieldEditingDelegate = self
        quizView.actionHandler = startQuiz
    }
    
    func setupDataSource() {
        dataSource.dataFetchDelegate = self
        quizView.setupTableView(dataSource: dataSource)
    }
    
    override func loadView() {
        view = quizView
    }
    
    func startQuiz() {
        quizView.updateCorrectAnswersCountLabel(text: "00/\(dataSource.quiz.answer.count)")
        quizViewModel.setTimer { [weak self] (currentTime) in
            self?.quizView.updateTimerLabel(text: currentTime)
        }
    }
}

// MARK: - Quiz Fetch Delegate
extension QuizViewController: QuizFetchDelegate {
    func didSetQuiz() {
        DispatchQueue.main.async {
            self.quizView.setTitle(text: self.dataSource.quiz.question)
        }
    }
    
    func didUpdateCorrectAnswers(isHitted: Bool) {
        DispatchQueue.main.async {
            if isHitted {
                self.quizView.insertRow(at: self.dataSource.correctAnswers.count - 1)
            } else {
                self.quizView.reloadTableView()
            }
        }
    }
    
    func didFailFetch(with error: NetworkError) {
        print("Error: \(error)")
    }
}

// MARK: - TextField Editing Delegate
extension QuizViewController: TextFieldEditingDelegate {
    func textFieldDidChange(_ textField: UITextField) {
        if !quizViewModel.quizStarted {
            textField.text = ""
            return
        }

        quizViewModel.verify(text: textField.text ?? "") { countAnswers in
            textField.text = nil
            quizView.updateCorrectAnswersCountLabel(text: countAnswers)
        }
    }
}
// MARK: - Quiz Status Delegate
extension QuizViewController: QuizStatusDelegate {
    func updateQuizStatus(to status: QuizStatus) {
        switch status {
        case .win:
            showAlert(title: "Congratulations",
                      message: "Good job! You found all the answers on time. Keep up with the great work.",
                      alertActionTitle: "Play Again")
        case .lose(let correctAnswersCount, let allAnswersCount):

            showAlert(title: "Time finished",
                      message: "Sorry, time is up! You got \(correctAnswersCount) out of \(allAnswersCount) answers",
                      alertActionTitle: "Try Again")
        }
    }
    
    func showAlert(title: String, message: String, alertActionTitle: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let replayAction = UIAlertAction(title: alertActionTitle, style: .default, handler: { [weak self] _ in
            self?.startQuiz()
        })
        
        alert.addAction(replayAction)
        present(alert, animated: true, completion: nil)
    }
    
}
