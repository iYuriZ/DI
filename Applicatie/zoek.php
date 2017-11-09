<?php
    require_once 'app/database.php';

    if(!isset($_GET['balienummer'])) {
        exit;
    }

    if(isset($_GET['searchquery'])) {
        $db = connectDatabase();

        $stmt = $db->prepare('SELECT 
                                p.passagiernummer,
                                p.naam,
                                p.passagiernummer,
                                pvv.vluchtnummer,
                                ivv.balienummer
                            FROM Passagier p INNER JOIN PassagierVoorVlucht pvv
                                ON pvv.passagiernummer = p.passagiernummer
                            INNER JOIN IncheckenVoorVlucht ivv
                                ON ivv.vluchtnummer = pvv.vluchtnummer
                            WHERE
                                p.naam LIKE ?
                            AND
                                ivv.balienummer = ?');
        $stmt->execute([
            '%'.$_GET['searchquery'].'%',
            $_GET['balienummer']
        ]);

        $passagiers = [];
        while ($row = $stmt->fetch()) {
            array_push($passagiers, $row);
        }
    }
?>

<!doctype html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <title>Home</title>
    <link rel="stylesheet" href="CSS/Style.css">
    <link rel="stylesheet" href="CSS/bootstrap.css">
</head>

<body>

<div class="row main-container">
    <div class="col-md-4"></div>

    <main class="col-md-4">
        <h1>Zoeken</h1>
        <p>Zoek een passagier op basis van de voor- en achternaam.</p>

        <form class="form-group row" method="GET">
            <input type="hidden" name="balienummer" value="<?= $_GET['balienummer'] ?>"/>
            <input type="text" class="form-control" name="searchquery" value="<?= isset($_GET['searchquery']) ? $_GET['searchquery'] : '' ?>"/>
            <br>
            <button class="btn btn-info" name="btn_search">Zoek</button>
        </form>

        <!-- Resultaten -->
        <div class="row">
            <?php if (isset($passagiers) && count($passagiers) > 0) : ?>
                <table class="table table-bordered table-striped table-hover">
                    <thead>
                        <th>Naam</th>
                        <th>Passagiernummer</th>
                        <th>Vluchtnummer</th>
                    </thead>
                    <tbody>
                        <?php foreach($passagiers as $passagier): ?>
                            <tr>
                                <td>
                                    <a href="passagier.php?passagiernummer=<?= $passagier['passagiernummer'] ?>&vluchtnummer=<?= $passagier['vluchtnummer'] ?>&balienummer=<?= $_GET['balienummer'] ?>">
                                        <?= $passagier['naam'] ?>
                                    </a>
                                </td>
                                <td>
                                    <a href="passagier.php?passagiernummer=<?= $passagier['passagiernummer'] ?>&vluchtnummer=<?= $passagier['vluchtnummer'] ?>&balienummer=<?= $_GET['balienummer'] ?>">
                                        <?= $passagier['passagiernummer'] ?>
                                    </a>
                                </td>
                                <td>
                                    <a href="passagier.php?passagiernummer=<?= $passagier['passagiernummer'] ?>&vluchtnummer=<?= $passagier['vluchtnummer'] ?>&balienummer=<?= $_GET['balienummer'] ?>">
                                        <?= $passagier['vluchtnummer'] ?>
                                    </a>
                                </td>
                            </td>
                        <?php endforeach; ?>
                    </tbody>
                </table>
            <?php elseif (isset($passagiers)): ?>
                <h3>Geen gebruikers gevonden</h3>
            <?php endif; ?>
        </div>
    </main>

    <div class="col-md-4"></div>
</div>

</body>

</html>
