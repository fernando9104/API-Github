//
//  ViewController.swift
//  API_Github
//
//  Created by Developer02 on 26/10/18.
//  Copyright © 2018 Developer02. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    // Variables y constantes generales de la clase
    @IBOutlet weak var user_text_fld: UITextField!
    @IBOutlet weak var userName_label: UILabel!
    @IBOutlet weak var name_label: UILabel!
    @IBOutlet weak var location_label: UILabel!
    @IBOutlet weak var email_label: UILabel!
    @IBOutlet weak var company_label: UILabel!
    @IBOutlet weak var created_label: UILabel!
    @IBOutlet weak var repo_label: UILabel!
    @IBOutlet weak var avatar_image: UIImageView!
    @IBOutlet weak var dataTableView: UITableView!
    @IBOutlet weak var buttons_contr_bottom: NSLayoutConstraint!
    
    var baseUrl:String = "https://api.github.com/users/"
    var repoDataArray:[[String:String]] = [[String:String]]()
    var gitUserReposURL:String?
    var progressView: UIViewController?
    var currentGitUser:String?
    
    // Constructor
    override func viewDidLoad() {
        super.viewDidLoad()
        
        currentGitUser = ""
        
        // Delcara eventos para el teclado
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    // Funcion que dectecta el tamanio del taclado mostrandolo o escondiendolo
    @objc private func keyboardShow( notify: NSNotification ){
        keyboardAdjusHeight(keyShow: true, notify: notify)
    }
    @objc private func keyboardHide( notify: NSNotification ){
        keyboardAdjusHeight(keyShow: false, notify: notify)
    }
    private func keyboardAdjusHeight( keyShow:Bool, notify:NSNotification ){
        var userInfo = notify.userInfo!
        let keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        let animationDurarion = userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as! TimeInterval
        let changeInHeight = ( keyboardFrame.height ) * (keyShow ? 1 : -1)
        
        UIView.animate(withDuration: animationDurarion, animations: {
            self.buttons_contr_bottom.constant += changeInHeight
        })
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        progressView = segue.destination
    }
    
    // Funcion que escucha el evento touch de los botones
    @IBAction func button_event(_ sender: UIButton) {
        
        // Identifica el tag del boton
        switch( sender.tag ){
            case 1: // Shearch
                if ( user_text_fld.text == "" ){
                    // Codigo para mas adelante
                }else{
                    // Verifica que el usuario a consultar sea diferente al actual
                    if( user_text_fld.text != currentGitUser ){
                        // Activa el seguir de la vista del progresso
                        currentGitUser = user_text_fld.text
                        performSegue(withIdentifier: "progressView", sender: nil)
                        executeRequest(typeReq: "gitUser");
                    }
                }
                break;
            case 2: // Clear
                // Imagen por defecto
                avatar_image.image = #imageLiteral(resourceName: "Face")
                currentGitUser = ""
               
                // Limpia Campos
                if( userName_label.text != "" ){
                    userName_label.text = ""
                }
                if( name_label.text != "" ){
                    name_label.text = ""
                }
                if( location_label.text != "" ){
                    location_label.text = ""
                }
                if( email_label.text != "" ){
                    email_label.text = ""
                }
                if( company_label.text != "" ){
                    company_label.text = ""
                }
                if( created_label.text != "" ){
                    created_label.text = ""
                }
                if( repo_label.text != "" ){
                    repo_label.text = ""
                    
                }
                if( user_text_fld.text != "" ){
                    user_text_fld.text = ""
                }
                repoDataArray.removeAll()
                dataTableView.reloadData()
                break;
            default:
                break;
        }// Fin del switch
        
    }// fin de la funcion button_event
    
    /* Funcionq que prepara y configura la peticion requerida */
    private func executeRequest( typeReq: String ){
        
        var stringUrl:String = ""
        
        // Identifica el tipo de peticion
        switch typeReq {
            case "gitUser":
                // Url para la peticion
                if let userText = user_text_fld.text {
                    stringUrl = baseUrl + userText
                }
                break;
            case "gitRepo":
                stringUrl = gitUserReposURL!
                break;
            default:
                break;
        }// Fin del switch
        
        // Crea objetos URL para lanzar la peticion
        guard let url = URL( string: stringUrl ) else { return }
        let session   = URLSession.shared
        
        // Lanza la tarea de la peticion
        session.dataTask(with: url){ (data, response, error ) in
            
            // Verifica veracidad de la peticion
            guard let httpUrlResponse = response as? HTTPURLResponse else {
                DispatchQueue.main.async { self.progressView?.dismiss(animated: true, completion: nil) }
                return
            }
            // Verifica el estado de la peticion
            guard let statusRequest = httpUrlResponse.allHeaderFields["Status"] as? String else {
                DispatchQueue.main.async { self.progressView?.dismiss(animated: true, completion: nil) }
                return
            }
        
            var showPopUp:Bool  = false
            var verifyData:Bool = true
            
            // Identifica el estado de la peticion
            switch( statusRequest ){
                case "404 Not Found":
                    showPopUp  = true
                    verifyData = false
                    break;
                case "304 Not Modified":
                    break;
                case "200 OK":
                    break;
                default:
                    showPopUp  = true
                    verifyData = false
                    break;
            }// Fin del switch
            
            // Verifica los datos
            if( verifyData ){
                DispatchQueue.main.async { // Hilo que controla la interfaz grafica
                    // Identifica el tipo de peticion
                    switch typeReq {
                        case "gitUser":
                            let jsonRequest = try? JSONSerialization.jsonObject( with: data!, options: [] ) as? [String: Any]
                            self.setUserDataGit( jsonRequest: jsonRequest!! )
                            break;
                        case "gitRepo":
                            let jsonRequest = try? JSONSerialization.jsonObject( with: data!, options: [] ) as? [[String: Any]]
                            self.setRepoDataGit( jsonRequest: jsonRequest!! )
                            break;
                        default:
                            break;
                    }// Fin del switch
                }
            }else{
                DispatchQueue.main.async {
                    self.progressView?.dismiss(animated: true, completion: {
                        // Verifica si puede mostar ventana modal
                        if( showPopUp ){
                            // Activa el seguir de la ventana de usuario con disponible
                            self.performSegue(withIdentifier: "popUpWin", sender: nil)
                        }
                    })
                }
            }
        }.resume()
        
    }// Fin de la funcion executeRequest
    
    /* Funcion encargada de configurar los datos primarios del usuario git consultado. */
    private func setUserDataGit( jsonRequest: [ String: Any ] ){
        
        // Configura los elementos de la vista con los datos correspondientes
        if let avatarUrl    = jsonRequest["avatar_url"] as? String {
            let imageUrl    = URL(string: avatarUrl)
            let imageData   = try? Data(contentsOf: imageUrl!)
            avatar_image.image = UIImage(data: imageData!)
        }
        if let userName = jsonRequest["login"] as? String {
            userName_label.text = userName
        }
        if let name = jsonRequest["name"] as? String {
            name_label.text = name
        }
        if let location = jsonRequest["location"] as? String {
            location_label.text = location
        }
        if let email = jsonRequest["email"] as? String {
            email_label.text = email
        }
        if let company = jsonRequest["company"] as? String {
            company_label.text = company
        }
        if let created = jsonRequest["created_at"] as? String {
            created_label.text = created
        }
        if let repos = jsonRequest["public_repos"] as? Int {
            self.repo_label.text = String(repos)
            gitUserReposURL = jsonRequest["repos_url"] as? String ?? ""
        }
        
        // Se limpia datos viejos o anteriores
        if( repoDataArray.count > 0 ){
            repoDataArray.removeAll()
            dataTableView.reloadData()
        }
        
        //
        if( self.repo_label.text == "" ){
            progressView?.dismiss(animated: true, completion: nil)
        }else{
            executeRequest(typeReq: "gitRepo");
        }
    
    } // Fin de la funcion setUserDataGit
    
    /* Funcion encargada de configurar los datos de repositorio del usuario git consultado. */
    private func setRepoDataGit( jsonRequest: [[ String: Any ]] ){
        
        // Itera los datos de la peticion
        for repoDataObj in jsonRequest {
            repoDataArray.append([
                "name": repoDataObj["name"] as? String ?? "",
                "private": repoDataObj["private"] as? String ?? "No",
                "description": repoDataObj["description"] as? String ?? "",
                "cloneUrl": repoDataObj["clone_url"] as? String ?? "",
                "language": repoDataObj["language"] as? String ?? "",
                "created": repoDataObj["created_at"] as? String ?? ""
            ])
        }// Fin del ciclo
        
        dataTableView.reloadData()
        progressView?.dismiss(animated: true, completion: nil)
        
    }// Fin de la funcion setRepoDataGit

}// Extension para la clase ViewController
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return repoDataArray.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let customCell = tableView.dequeueReusableCell( withIdentifier: "data_cell", for: indexPath ) as? RepoDataViewCell
        customCell?.setData( repoData:repoDataArray[indexPath.row] )
        return customCell!
    }
}
extension ViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        
    }
}
    
// Clase de para la vista personalizada del tableView
class RepoDataViewCell: UITableViewCell {
    
    @IBOutlet weak var name_vl_cel: UILabel!
    @IBOutlet weak var desc_vl_cel: UILabel!
    @IBOutlet weak var private_vl_cel: UILabel!
    @IBOutlet weak var clone_vl_cel: UILabel!
    @IBOutlet weak var lang_vl_cel: UILabel!
    @IBOutlet weak var created_vl_cel: UILabel!

    public func setData( repoData: [String:Any] ){
        // Configura los datos en la vista
        name_vl_cel.text    = repoData["name"] as? String
        desc_vl_cel.text    = repoData["description"] as? String
        private_vl_cel.text = repoData["private"] as? String
        clone_vl_cel.text   = repoData["cloneUrl"] as? String
        lang_vl_cel.text    = repoData["language"] as? String
        created_vl_cel.text = repoData["created"] as? String
    }
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected( selected, animated:animated )
    }
}// Fin de la clase RepoDataViewCell
