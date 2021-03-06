//
//  CocktailNameListViewModel.swift
//  CocktailMaster
//
//  Created by Hyeontae on 2021/04/15.
//

import Foundation
import Swinject
import RxRelay
import SwinjectAutoregistration

protocol CocktailNameListViewModeling: BaseViewModeling {
    var startedAlphabet: String { get }
    var cocktailListRelay: BehaviorRelay<[CocktailInfoEntity]> { get }
    var cocktailDetailViewControllerRelay: PublishRelay<CocktailDetailViewController> { get }
    
    func getCocktailList()
    func targetCocktail(at indexPath: IndexPath) -> CocktailInfoEntity?
    func didTapCocktailCell(at indexPath: IndexPath)
}

final class CocktailNameListViewModel: BaseViewModel, CocktailNameListViewModeling {
    let startedAlphabet: String
    let cocktailListRelay = BehaviorRelay<[CocktailInfoEntity]>(value: [])
    let cocktailDetailViewControllerRelay = PublishRelay<CocktailDetailViewController>()
    
    let cocktailProvider = CocktailProvider()
    let assembler = Assembler([MainAssembly(), CocktailListAssembly()])
    
    init(_ startedAlphabet: String) {
        self.startedAlphabet = startedAlphabet
        super.init()
        getCocktailList()
    }
    
    func getCocktailList() {
        cocktailProvider.cocktailList(startedAlphabet)
            .subscribe { [weak self] result in
                self?.cocktailListRelay.accept(result.drinks)
            } onError: { err in
                print(err)
            }
            .disposed(by: bag)
    }
    
    func targetCocktail(at indexPath: IndexPath) -> CocktailInfoEntity? {
        let cocktailList = cocktailListRelay.value
        guard indexPath.row < cocktailList.count else { return nil }
        return cocktailList[indexPath.row]
    }
    
    func didTapCocktailCell(at indexPath: IndexPath) {
        guard let selectedCocktail = targetCocktail(at: indexPath) else { return }
        
        let viewModel = assembler.resolver ~> (CocktailDetailViewModeling.self, argument: selectedCocktail.idDrink)
        guard let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CocktailDetailViewController") as? CocktailDetailViewController else { return }
        viewController.viewModel = viewModel
        cocktailDetailViewControllerRelay.accept(viewController)
    }
}

class CocktailListAssembly: Assembly {
    func assemble(container: Container) {
        container.register(CocktailDetailViewModeling.self) { (_, id: String) in
            
            let test = container.resolve(CocktailNameListViewModeling.self, argument: "z")
            if let test = test as? CocktailNameListViewModel {
                print("Integration")
                print(test.startedAlphabet)
            } else {
                print("not Integrated")
            }
            
            return CocktailDetailViewModel(id)
        }
    }
}
